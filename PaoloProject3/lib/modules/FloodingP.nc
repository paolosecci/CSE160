// Module
#include "../../includes/channels.h"
#include "../../includes/lsp.h"
#include "../../includes/CommandMsg.h"

module FloodingP
{
  provides interface SimpleSend as FloodSender;
  provides interface SimpleSend as LSPSender;
  provides interface SimpleSend as RouteSender;

  // Internal
  uses interface SimpleSend as InternalSender;
  uses interface Receive as InternalReceiver;
  uses interface List<pack> as PacketList;
  uses interface List<lspLink> as LspLinkList;
  uses interface NeighborDiscovery;
  uses interface Hashmap<int> as RoutingTable;
}

implementation
{
  //vars
  uint16_t seqNum = 0;
  pack sendPack;
  uint32_t tempDest;//nextdest

  //functions
  void makePack(pack *Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
  bool findPack(pack *Packet);
  void checkInPack(pack *myMsg);

  lspLink lspL;
  uint16_t lspAge = 0;

  command error_t FloodSender.send(pack msg, uint16_t dest)
  {
    msg.src = TOS_NODE_ID;
    msg.protocol = PROTOCOL_PING;
    msg.seq = seqNum++;
    msg.TTL = MAX_TTL;
    //dbg(FLOODING_CHANNEL, "Flooding Network: %s\n", msg.payload);
    call InternalSender.send(msg, AM_BROADCAST_ADDR);
  }

  command error_t LSPSender.send(pack msg, uint16_t dest)
  {
    //dbg(ROUTING_CHANNEL, "LSP Network: %s\n", msg.payload);
    call InternalSender.send(msg, AM_BROADCAST_ADDR);
  }

  command error_t RouteSender.send(pack msg, uint16_t dest)
  {
    msg.seq = seqNum++;
    call InternalSender.send(msg, dest);
  }


  event message_t* InternalReceiver.receive(message_t* msg, void* payload, uint8_t len)
  {
    //dbg(FLOODING_CHANNEL, "Receive: %s", msg.payload);
    if(len==sizeof(pack))
    {
      pack* myMsg=(pack*) payload;
      if(myMsg->TTL == 0 || findPack(myMsg))//is pack's ttl expired or have we seen it before?
      {
        //Drop pack (i.e. do nothing)
        return  msg;
      }
      else if(TOS_NODE_ID == myMsg->dest)
      {   //at dest
          dbg(FLOODING_CHANNEL, "Packet arrived: %d -> %d\n",myMsg->src,myMsg->dest);
          dbg(GENERAL_CHANNEL, "Packet Payload: %s\n", myMsg->payload);

          if(myMsg->protocol == PROTOCOL_PING)
          {
              dbg(GENERAL_CHANNEL, "PINGREPLY TRIGGERED \n");
              dbg(FLOODING_CHANNEL, "Pinging: %d -> %d with seq %d\n", myMsg->dest, myMsg->src, myMsg->seq);

              checkInPack(myMsg);
              if(call RoutingTable.contains(myMsg -> src))
              {
                  dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", myMsg->src, call RoutingTable.get(myMsg->src));
                  makePack(&sendPack, myMsg->dest, myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
                  call InternalSender.send(sendPack, call RoutingTable.get(myMsg->src));
              }
              else
              {
                  dbg(NEIGHBOR_CHANNEL, "couldn't route to %d, so flooding...\n", myMsg->src); //why TOS_NODE_ID
                  makePack(&sendPack, myMsg->dest, myMsg->src, myMsg->TTL-1, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
                  call InternalSender.send(sendPack, AM_BROADCAST_ADDR);
              }
              return msg;
          }
          else if(myMsg->protocol == PROTOCOL_PINGREPLY)
          {
              dbg(FLOODING_CHANNEL, "Received Ping Reply from: %d\n", myMsg->src);
          }
          return msg;
      }

      else if(myMsg->dest == AM_BROADCAST_ADDR)
      {
          if(myMsg->protocol == PROTOCOL_LINKSTATE)
          {
            uint16_t i, j, k;
            bool alreadyLinked = FALSE;

            for(i = 0; i < call LspLinkList.size(); i++)
            {
              lspLink LSP = call LspLinkList.get(i);
              if(LSP.src == myMsg->src)//do we have a link to this node already
              {
                for(j = 0; j < myMsg->seq; j++)
                {
                  if(LSP.neighbor == myMsg->payload[j])
                  {
                    alreadyLinked = TRUE;
                  }
                }
              }

            }
            if(!alreadyLinked)
            {
              for(k = 0; k < myMsg->seq; k++)
              {//traverse SRC's neighbors, , and add to LSP_LINK_LIST
                  lspL.neighbor = myMsg->payload[k];
                  lspL.cost = 1;
                  lspL.src = myMsg->src;
                  call LspLinkList.pushback(lspL);
                  //dbg(ROUTING_CHANNEL,"$$$Neighbor: %d\n",lspL.neighbor);
              }
              //keep flooding
              makePack(&sendPack, myMsg->src, AM_BROADCAST_ADDR, myMsg->TTL-1 , PROTOCOL_LINKSTATE, myMsg->seq, (uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
              call InternalSender.send(sendPack, AM_BROADCAST_ADDR);
            }
          }
          //neighbor discovery packets land here
          if(myMsg->protocol == PROTOCOL_PING)
          {
            //dbg(GENERAL_CHANNEL,"Starting Neighbor Discover for %d\n",myMsg->src);
            makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL-1 , PROTOCOL_PINGREPLY, seqNum, (uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
            //WE R A ROUTER! check TOS_NODE_ID and destination
            call InternalSender.send(sendPack, myMsg->src);
          }
          if(myMsg->protocol == PROTOCOL_PINGREPLY)
          {
            //current directory: neighbor
            //dbg(GENERAL_CHANNEL,"AT Neighbor PingReply\n");
            call NeighborDiscovery.neighborReceived(myMsg);
          }
          //call lsrTimer.startPeriodic(60000 + (uint16_t)((call Random.rand16())%200));
          return msg;
      }
      else
      {
          checkInPack(myMsg);
          if(call RoutingTable.contains(myMsg -> src))
          {//route and send to destinatoin
            dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", myMsg -> dest, call RoutingTable.get(myMsg -> dest));
            makePack(&sendPack, myMsg->src, myMsg->dest, myMsg->TTL-1, PROTOCOL_LINKSTATE, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
            call InternalSender.send(sendPack, call RoutingTable.get(myMsg -> dest));
          }
          else
          {
            dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for:%d so flooding\n",TOS_NODE_ID);//so we r sending this internally
            makePack(&sendPack, myMsg->src, myMsg->dest, myMsg->TTL-1, PROTOCOL_PING, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
            call InternalSender.send(sendPack, AM_BROADCAST_ADDR);
          }
          return msg;
      }
    }
    dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
    return msg;
  }

  //PROJ1 METHODS

  //if waldoPack found in PacketList, return TRUE... else, return FALSE
  bool findPack(pack *waldoPack)
  {
    uint16_t size = call PacketList.size();
    uint16_t i = 0;
    pack potentialWaldo;
    for(i = 0; i < size; i++)
    {//traverse packetlist
        potentialWaldo = call PacketList.get(i);
        if(potentialWaldo.src == waldoPack->src && potentialWaldo.dest == waldoPack->dest && potentialWaldo.seq == waldoPack->seq)
        {
          return TRUE;
        }
    }
    //if we get here without returning TRUE, we couldnt find waldo
    return FALSE;
  }

  //push pack to packet list...if packet list full, pop oldest and then push
  void checkInPack(pack *P)
  {
    if (call PacketList.isFull()) //check if list is full
    {
       call PacketList.popfront(); //if so, remove the oldest item
		}
    call PacketList.pushfront(*P);//QQQ: why not the back?
	}

  void makePack(pack *Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length)
  {
    Packet->src = src;
    Packet->dest = dest;
    Packet->TTL = TTL;
    Packet->seq = seq;
    Packet->protocol = protocol;
    memcpy(Packet->payload, payload, length);
  }
}
