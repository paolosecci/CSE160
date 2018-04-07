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
#include "includes/lsp.h"//proj2
#include "includes/socket.h"//proj3

module Node
{
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;
   uses interface SimpleSend as FloodSender;
   uses interface SimpleSend as RouteSender;

   uses interface Hashmap<int> as RoutingTable;
   uses interface List<socket_store_t> as Sockets;

   uses interface CommandHandler;
   uses interface NeighborDiscovery;
   uses interface LinkState;
   uses interface Transport;

}

implementation
{
   pack sendPack;

   //Prototypes
   void makePack(pack *Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted()
   {
      call AMControl.start();
      //dbg(GENERAL_CHANNEL, "Booted\n");
      call NeighborDiscovery.start();
      call LinkState.start();
   }

   event void AMControl.startDone(error_t err)
   {
      if(err == SUCCESS)
      {
         //dbg(GENERAL_CHANNEL, "Radio On\n");
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
     dbg(GENERAL_CHANNEL, "Packet Received\n");
     if(len==sizeof(pack))
     {
        pack* myMsg=(pack*) payload;
        dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
        return msg;
     }
     dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
     return msg;
   }

   //PING EVENT
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload)
   {
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      if(call RoutingTable.contains(destination))
      {
          makePack(&sendPack, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_LINKSTATE, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
          dbg(NEIGHBOR_CHANNEL, "To get to:%d, send through:%d\n", destination, call RoutingTable.get(destination));
          call RouteSender.send(sendPack, call RoutingTable.get(destination));
      }
      else
      {
          makePack(&sendPack, TOS_NODE_ID, destination, 0, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
          dbg(NEIGHBOR_CHANNEL, "Coudn't route to:%d so flooding...\n", TOS_NODE_ID);
          call FloodSender.send(sendPack, destination);
      }
   }

   event void CommandHandler.printNeighbors()
   {
     call NeighborDiscovery.print();
   }
   event void CommandHandler.printRouteTable()
   {
     call LinkState.printRoutingTable();
   }
   event void CommandHandler.printLinkState()
   {
     call LinkState.print();
   }
   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(uint16_t port)
   {
     //dbg(ROUTING_CHANNEL,"SETTING UP TEST SERVER for %d on port %d\n", TOS_NODE_ID);

     socket_addr_t serverAddress;
     socket_t fd = call Transport.socket();
     serverAddress.addr = TOS_NODE_ID;
     serverAddress.port = port;

     if(call Transport.bind(fd, &serverAddress) == SUCCESS)
     {
       dbg(TRANSPORT_CHANNEL, "SERVER: WE MADE IT!\n");
     }
     if(call Transport.listen(fd) == SUCCESS)
     {
       dbg(TRANSPORT_CHANNEL, "listening...\n");
     }

     dbg(TRANSPORT_CHANNEL, "Node %d set as server\nport: %d\n", TOS_NODE_ID, port);
     dbg(TRANSPORT_CHANNEL, "fd is %d\n", fd);

   }
   event void CommandHandler.setTestClient(uint16_t dest, uint16_t srcPort, uint16_t destPort, uint16_t transfer)
   {
     //dbg(ROUTING_CHANNEL,"SETTING UP TEST CLIENT\n");

     pack syn;
     socket_store_t synSocket;
     socket_addr_t clientAddress;
     socket_addr_t serverAddress;
     socket_t fd = call Transport.socket();
     clientAddress.addr = TOS_NODE_ID;
     clientAddress.port = srcPort;
     serverAddress.addr = dest;
     serverAddress.port = destPort;

     if(call Transport.bind(fd, &clientAddress) == SUCCESS)
     {
       dbg(TRANSPORT_CHANNEL, "CLIENT: WE MADE IT!\n");
     }

     call Transport.connect(fd, &serverAddress);//send SYN pack
     dbg(TRANSPORT_CHANNEL, "Node %d set as client\nsrc port: %d\tdest addr: %d\tdest port:%d\n", TOS_NODE_ID, srcPort, dest, destPort);
   }

   event void CommandHandler.setAppServer(){}
   event void CommandHandler.setAppClient(){}

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
