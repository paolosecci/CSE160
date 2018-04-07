// Module
#include "../../includes/channels.h"
#include "../../includes/packet.h"

#define BEACON_PERIOD 1000
#define MAX_NEIGHBOR_AGE 7

module NeighborDiscoveryP
{
  provides interface NeighborDiscovery;
  // Internal
  uses interface Timer<TMilli> as NeigborDiscoveryTimer;
  uses interface SimpleSend as FloodSender;
  uses interface List<pack> as NeighborList;
  uses interface Random as Random;

}

implementation
{
  pack sendPack;
  uint16_t seqNum = 0;
  uint16_t neighborAge = 0;
  bool findNeighbor(pack *Packet);
  void removeNeighbors();
  void makePack(pack *Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

  command void NeighborDiscovery.start()
  {
    uint32_t startTime;
    dbg(GENERAL_CHANNEL, "Booted\n");
    startTime = (20000 + (uint16_t) ((call Random.rand16())%5000));;

    call NeigborDiscoveryTimer.startOneShot(startTime);
  }

  command void NeighborDiscovery.neighborReceived(pack *myMsg)
  {
    if(!findNeighbor(myMsg))
    {
      call NeighborList.pushback(*myMsg);
    }
  }

  command void NeighborDiscovery.print()
  {
    if(call NeighborList.size() > 0)
    {
       uint16_t neighborListSize = call NeighborList.size();
       uint16_t i = 0;
       //dbg(NEIGHBOR_CHANNEL, "***the NEIGHBOUR size of node %d is :%d\n",TOS_NODE_ID, neighborListSize);
       for(i = 0; i < neighborListSize; i++)
       {
         pack n = call NeighborList.get(i);
         dbg(NEIGHBOR_CHANNEL, "***the NEIGHBORS  of node  %d is :%d\n", TOS_NODE_ID, n.src);
       }
    }
    else
    {
       dbg(COMMAND_CHANNEL, "***0 NEIGHBORS  of node  %d!\n",TOS_NODE_ID);
    }
  }

  event void NeigborDiscoveryTimer.fired()
  {
    char* neighborPayload = "Neighbor Discovery";
    uint16_t size = call NeighborList.size();
    uint16_t i = 0;
    if(neighborAge == MAX_NEIGHBOR_AGE)//if too old (older than 7), drop
    {
      //dbg(NEIGHBOR_CHANNEL,"removing neighbor of %d with Age %d \n",TOS_NODE_ID,neighborAge);
      neighborAge = 0;
      for(i = 0; i < size; i++)
      {
        call NeighborList.popfront();
      }
    }
    makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, seqNum,  (uint8_t*) neighborPayload, PACKET_MAX_PAYLOAD_SIZE);
    neighborAge++;

    call FloodSender.send(sendPack, AM_BROADCAST_ADDR);
  }

  void removeNeighbors()
  {
    uint16_t size = call NeighborList.size();
    uint16_t i = 0;
    for(i = 0; i < size; i++)
    {
      call NeighborList.popback();
    }
  }

  bool findNeighbor(pack *Pack)
  {
    uint16_t size = call NeighborList.size();
    uint16_t i = 0;
    pack potentialNeighbor;
    for(i = 0; i < size; i++)
    {
      potentialNeighbor = call NeighborList.get(i);
      if(potentialNeighbor.src == Pack->src && potentialNeighbor.dest == Pack->dest)
      {
        return TRUE;
      }
    }
    return FALSE;
  }

  void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length)
  {
     Package->src = src;
     Package->dest = dest;
     Package->TTL = TTL;
     Package->seq = seq;
     Package->protocol = protocol;
     memcpy(Package->payload, payload, length);
  }
}
