//UCM Skeleton Node.nc//

/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

typedef nx_struct Neighbor
{
    nx_uint16_t Node;
    nx_uint8_t Age;
}   Neighbor;

typedef nx_struct RoutingInfo
{
    nx_uint8_t nextHop;
    nx_uint8_t cost;
}   RoutingInfo;

typedef nx_struct RoutingTable
{
    RoutingInfo dests[20];
}   RoutingTable;

typedef nx_struct SeenPack
{
    nx_uint8_t srcID;
    nx_uint8_t seqNum;
}   SeenPack;

typedef nx_struct LSpack
{
	  nx_uint16_t dest;
	  nx_uint16_t src;
	  nx_uint16_t seq;
	  nx_uint8_t TTL;
	  nx_uint8_t protocol;
    nx_uint8_t neighbors[PACKET_MAX_PAYLOAD_SIZE];
}   LSPack;

module Node
{
   uses interface Boot;
   uses interface Timer<TMilli> as Timer1; //node established timer to set firing periods for flooding
   uses interface Random as Random; //randomize timing to create firing period/ avoids collisions
   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface List<Neighbor> as NeighborList;
   uses interface List<Neighbor> as NeighborsDropped;
   uses interface List<Neighbor> as Neighborhood;
   uses interface List<SeenPack> as SeenPacks;//really its the mailman's bag //node creates list of packs it has s.recieved

   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
}

implementation
{
   pack sendPack;
   LSPack sendLSP;
   RoutingTable myRoutingTable;
   SeenPack sp;

   uint16_t seqNum = 0;

   //Prototypes
   void makePack(pack *Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void updateSeenPacks(SeenPack alreadySeenPack);

   void discoverNeighbors();
   void checkInNeighbor(uint16_t neighbor);
   void printNeighbors();

   void sendLSPack(uint8_t TTL);

   void updateRoutingTable(LSPack nieghborLSP, uint8_t neighborID);
   void initRoutingTable();
   void printRoutingTable();

   event void Boot.booted()
   {
      call AMControl.start();
      initRoutingTable();

      dbg(GENERAL_CHANNEL, "Booted\n");

   }
   event void Timer1.fired()
   {
      discoverNeighbors();
      sendLSPack(MAX_TTL);
   }

   event void AMControl.startDone(error_t err)
   {
      if(err == SUCCESS)
      {
         dbg(GENERAL_CHANNEL, "Radio On\n");
         call Timer1.startPeriodic((uint16_t)(call Random.rand16())%200);
      }
      else
      {
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   //MESSAGE RECIEVED
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
   {
      //dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len == sizeof(pack))
      {
         pack* messagePL = (pack*) payload;
         logPack(messagePL);

         if(messagePL->dest == TOS_NODE_ID)
         {
              /*
              if(PROTOCOL_PING == messagePL->protocol)
              {
                  //send back ping reply
                  makePack(&sendPack, TOS_NODE_ID, messagePL->src, MAX_TTL, PROTOCOL_PINGREPLY, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
                  call Sender.send(sendPack, myRoutingTable.dests[messagePL->src].nextHop);
                  seqNum++;
                  return msg;
              }
              else if(PROTOCOL_PINGREPLY == messagePL->protocol)
              {
                  //now we can send our queued packs
              }
              else //if not ping or ping reply
              {*/
                  sp.srcID = messagePL->src;
                  sp.seqNum = messagePL->seq;
                  updateSeenPacks(sp);
              //}
         }
         else if(messagePL->dest == AM_BROADCAST_ADDR)
         {
              if(messagePL->TTL > 0)
              {
                  if(PROTOCOL_NEIGHBOR_SEARCH == messagePL->protocol)
                  {
                      checkInNeighbor(messagePL->src);

                      makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_NEIGHBOR_REPLY, seqNum, 0, PACKET_MAX_PAYLOAD_SIZE);
                      seqNum++;
                      call Sender.send(sendPack, AM_BROADCAST_ADDR);

                      return msg;
                  }
                  else if(PROTOCOL_NEIGHBOR_REPLY == messagePL->protocol)
                  {
                      checkInNeighbor(messagePL->src);

                      //send back an ACK
                      //makePack(&sendPack, TOS_NODE_ID, messagePL->src, 1, PROTOCOL_LINKSTATE, seqNum, 0, PACKET_MAX_PAYLOAD_SIZE);
                      //seqNum++;
                      //call Sender.send(sendPack, messagePL->src);

                      return msg;
                  }
                  else if(PROTOCOL_LINKSTATE == messagePL->protocol)
                  {

                      LSPack* lspNeighbors = (LSPack*) messagePL->payload;
                      updateRoutingTable(*lspNeighbors, messagePL->src);
                      sendLSPack(messagePL->TTL--);
                  }
              }
              return msg; //TTL is 0... drop packet
         }
         else //dest is another Node
         {
              sp.srcID = messagePL->src;
              sp.seqNum = messagePL->seq;
              updateSeenPacks(sp);

              //forward this pack
              makePack(&sendPack, messagePL->src, messagePL->dest, messagePL->TTL--, messagePL->protocol, messagePL->seq, (void*) messagePL->payload, PACKET_MAX_PAYLOAD_SIZE);
              seqNum++;
              call Sender.send(sendPack, myRoutingTable.dests[messagePL->dest].nextHop);
         }
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }

   //PING EVENT
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload)
   {
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPack, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
      seqNum++;
      call Sender.send(sendPack, AM_BROADCAST_ADDR);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length)
   {
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   void discoverNeighbors()
   {
      makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, seqNum, PROTOCOL_NEIGHBOR_SEARCH, 0, PACKET_MAX_PAYLOAD_SIZE);
      seqNum++;
      call Sender.send(sendPack, AM_BROADCAST_ADDR);
   }

   void checkInNeighbor(uint16_t sourceID)
   {
      Neighbor n;

      int i;
      bool isInNeighborList = FALSE;

      for(i = 0; i < call NeighborList.size(); i++)
      {
          n = call NeighborList.get(i);
          if(n.Node == sourceID)
          {
              isInNeighborList = TRUE;//already in neighbor list

              n.Age = 0;
              call NeighborList.editspot(n, i);
          }
          else if(n.Age > 5)
          {
              n = call NeighborList.popspot(i);
              call NeighborsDropped.pushback(n);
              i--;
          }
          else
          {
              n.Age += 1;
              call NeighborList.editspot(n, i);
          }
      }

      if(isInNeighborList)
      {
          return;
      }
      else
      {
          n.Node = sourceID;
          n.Age = 0;
          call NeighborList.pushback(n);
          return;
      }
   }

   void updateSeenPacks(SeenPack spack)
   {
      int i;
      bool alreadySeen = FALSE;
      SeenPack listedPack;

      for(i = 0; i < call SeenPacks.size(); i++)
      {
          listedPack = call SeenPacks.get(i);
          if(spack.srcID == listedPack.srcID && spack.seqNum == listedPack.seqNum)
          {
              alreadySeen = TRUE;
          }
      }

      if(!alreadySeen)
      {
          call SeenPacks.pushback(spack);
      }
      return;
   }

   void initRoutingTable()
   {
      int i;
      //fill costs with infinity
      for(i = 0; i < 20; i++)
      { //set all cost to 25o (biggest possible uint8_t - 5)
          myRoutingTable.dests[i].cost = 250;
      }

      //edit info for dest = me
      myRoutingTable.dests[TOS_NODE_ID].nextHop = TOS_NODE_ID;
      myRoutingTable.dests[TOS_NODE_ID].cost = 0;

      //edit info for neighbors in NeighborList
      for(i = 0; i < call NeighborList.size(); i++)
      {
          Neighbor n = call NeighborList.get(i);
          myRoutingTable.dests[n.Node].cost = 1;
          myRoutingTable.dests[n.Node].nextHop = n.Node;
      }
   }

   void updateRoutingTable(LSPack neighborLSP, uint8_t neighborID)
   {
      //costToHim = costToHisNeighbors + 1;
      //costToHim = myRoutingTable.dest[neighborID].cost;

      //costToHisNeighbors = costToHim + 1;
      //costToHisNeighbors = myRoutingTable.dests[n.Node].cost

      int i;
      for(i = 0; neighborLSP.neighbors[i] >= 0 ; i++) //Djikstra's
      {
          uint8_t n = neighborLSP.neighbors[i];

          if(myRoutingTable.dests[n].cost > 1 + myRoutingTable.dests[neighborID].cost)
          {
              myRoutingTable.dests[n].cost = 1 + myRoutingTable.dests[neighborID].cost;
              myRoutingTable.dests[n].nextHop = myRoutingTable.dests[neighborID].nextHop;
          }
          else if(myRoutingTable.dests[n].cost + 1 < myRoutingTable.dests[neighborID].cost)
          {
              myRoutingTable.dests[neighborID].cost = 1 + myRoutingTable.dests[n].cost;
              myRoutingTable.dests[neighborID].nextHop = myRoutingTable.dests[n].nextHop;
          }
      }
      return;
   }

   void printRoutingTable()
   {
      int i;
      dbg(ROUTING_CHANNEL, "Routing Table: Node %s\nDest\tNextHop\tCost\n", TOS_NODE_ID);
      for(i = 0; i < 20; i++)
      {
          dbg(ROUTING_CHANNEL, "%s\t%s\t%s\n", i, myRoutingTable.dests[i].nextHop, myRoutingTable.dests[i].cost);
      }
      dbg(ROUTING_CHANNEL, "\n");
   }

   void sendLSPack(uint8_t ttl)
   {
      int i;
      int numOfNeighbors = call NeighborList.size();
      for(i = 0; i < numOfNeighbors; i++)
      {
          Neighbor n = call NeighborList.get(i);
          sendLSP.neighbors[i] = n.Node;
      }
      for(i = numOfNeighbors; i < PACKET_MAX_PAYLOAD_SIZE; i++)
      {
          sendLSP.neighbors[i] = -1;
      }

      makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, ttl, PROTOCOL_LINKSTATE, seqNum, (void*) sendLSP.neighbors, PACKET_MAX_PAYLOAD_SIZE);
      seqNum++;
      call Sender.send(sendPack, AM_BROADCAST_ADDR);
   }
}
