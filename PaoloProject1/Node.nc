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

module Node
{
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;

   uses interface List<Neighbor*> as Neighborhood; //node creates list of node neighbors
   uses interface List<Neighbor*> as NeighborsDropped; //list of nodes removed from neighborsList
   uses interface List<uint32_t> as CheckList; //list of ints as CheckList of seen messages

   uses interface Timer<TMilli> as PeriodTimer; //node creates timer to create firing periods for sending packets
   uses interface Random as Random; //randomize timing to create firing period
}

implementation
{
   pack sendPacket;
   uint16_t seqCount = 0;

   //Packet Prototypes
 	 void makePack(pack* Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   //Neighbor Prototypes
   void updateNeighborhood(); //updates neighborhood
   void printNeighbors(); //finds neighbors in neighborhood
   void discoverNeighbors(); //sends out standard packet w protocol 8

   event void Boot.booted()
   {
     uint32_t start;
     uint32_t period;

     call AMControl.start();
     dbg(GENERAL_CHANNEL, "Booted\n");

     start = call Random.rand32() % 223;
		 period = call Random.rand32() % 991;

     call PeriodTimer.startPeriodicAt(start, period);
     dbg(GENERAL_CHANNEL, "start time: %d, firing period: %d\n", start, period);
   }

   event void AMControl.startDone(error_t err)
   {
     if(err == SUCCESS)
     {
        dbg(GENERAL_CHANNEL, "Radio On\n"); //connected
     }
     else
     {
        call AMControl.start(); //try again
     }
   }

   event void PeriodTimer.fired()
   {
     discoverNeighbors();
   }

   event void AMControl.stopDone(error_t err){}

   //MESSAGE RECIEVED
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
   {
      dbg(GENERAL_CHANNEL, "Packet Received\n");

      if(len == sizeof(pack))
      {
          //creates message with packet's payload
          pack* myMsg = (pack*) payload;

          //check if expired
          if(myMsg->TTL == 0) //checks if is packet TTL expired?
          {
            dbg(FLOODING_CHANNEL,"TTL expired: Dropping packet seq#%d from %d to %d\n", myMsg->seq, myMsg->src, myMsg->dest);
          }


          else if (myMsg->protocol == PROTOCOL_PINGREPLY) //found a Neighbor, add to neighborhood
          { //NEIGHBOR DISCOVERY
            Neighbor* neighborRecruit;
            Neighbor* neighborPtr;
            uint32_t i;
            bool neighborhoodMember = FALSE;

            for(i = 0; i < call CheckList.size(); i++) //check if this packet has been seen
            {
        					if(myMsg -> src == call CheckList.get(i))
      						return msg; //return msg if already seen / on checklist
        		}
            call CheckList.pushfront(myMsg -> src); //add to checklist if not seen

            if(!call Neighborhood.isEmpty())//if current Node has neighbors, increase their age
            {
                for(i = 0; i < call Neighborhood.size(); i++)
            		{
            					neighborPtr = call Neighborhood.get(i);
            					neighborPtr->Age = (neighborPtr->Age + 1); //increase age
        				}
      			}

            for (i = 0; i < call Neighborhood.size(); i++) //check if replying neighbor is already in neighborhood
            {
                neighborPtr = call Neighborhood.get(i);

                if (neighborPtr->Node == myMsg->src) //is the pingreply's src Node in neighborhood?
                {
                  neighborPtr->Age = 0; //reset Age to avoid unwanted dropping
                  neighborhoodMember = TRUE; //he's in the neighborhood
                }
            }
            if (!neighborhoodMember) //if not neighborhoodMember, add to neighborhood
            {
                //neighborRecruit = myMsg->src; //set recruit to message's src
                neighborRecruit->Node = myMsg->src;//set neighbor addy as src of neighbor_search_reply
                neighborRecruit->Age = 0; //reset Age to avoid unwanted dropping

                dbg(NEIGHBOR_CHANNEL, "New Neighbor\n");

                call Neighborhood.pushfront(neighborRecruit);
                neighborhoodMember = TRUE;
            }
            dbg(NEIGHBOR_CHANNEL, "Node %d is in the Neighborhood\n", myMsg->src);
            updateNeighborhood(); //drops old neighbors
          }

          else if (myMsg->protocol == PROTOCOL_PING)
          {
              //FLOODING
              if(myMsg->dest == TOS_NODE_ID)
              {
                  dbg(FLOODING_CHANNEL, "Packet has arrived. %d -> %d\n ", myMsg->src, myMsg->dest);
                  dbg(FLOODING_CHANNEL, "Payload: %s\n", myMsg->payload);
              }
      		    else //not at destination, keep flooding
              {
                  makePack(&sendPacket, TOS_NODE_ID, myMsg->dest, myMsg->TTL-1, PROTOCOL_PING, myMsg->seq, payload, PACKET_MAX_PAYLOAD_SIZE);
                  dbg(FLOODING_CHANNEL, "Packet found en route: %d -> %d\nRebroadcasting...\n", myMsg->src, myMsg->dest);
                  call Sender.send(sendPacket, AM_BROADCAST_ADDR);
      		    }
          }
          dbg(GENERAL_CHANNEL, "Node %d has dropped this packet.\n", TOS_NODE_ID);
          return msg;
      }
      else
      {
  		    dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
    	    return msg;
  		}
   }

   //PING EVENT
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload)
   {
      dbg(GENERAL_CHANNEL, "PING EVENT \n");

      // send next packet in sequence
      makePack(&sendPacket, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, seqCount, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPacket, AM_BROADCAST_ADDR);
      seqCount++;
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

  //MAKE PACK
  void makePack(pack* Packet, uint16_t src, uint16_t dest, uint16_t TTL,
                uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length)
  {
      Packet->src = src;
      Packet->dest = dest;
      Packet->TTL = TTL;
      Packet->seq = seq;
      Packet->protocol = protocol;
      memcpy(Packet->payload, payload, length);
  }

  //UPDATE NEIGHBORHOOD
  void updateNeighborhood()
  {
      Neighbor* n;
      uint32_t i;
      uint32_t size = call Neighborhood.size();

      for (i = 0; i < size; i++) //drop old neighbors
      {
        n = call Neighborhood.get(i); //get neighbor in neighborhood[i]

        if (n->Age > 3) //if Age > 3, drop the neighbor
        {
            call Neighborhood.popspot(i);
            dbg(NEIGHBOR_CHANNEL, "Node %d Dropped from Neighborhood due to more than 3 pings\n", n->Node);
            call NeighborsDropped.pushfront(n);//move neighbor to droppedList
            dbg(NEIGHBOR_CHANNEL, "Node %d Added to NeighborsDropped\n", n->Node);
            i--;
            size--;
        }
      }
  }
  //PRINT NEIGHBORS
  void printNeighbors()
  {
    updateNeighborhood();

		if(call Neighborhood.size() == 0) //if neighborhood is empty
    {
			dbg(NEIGHBOR_CHANNEL, "No Neighbors of Node %d found\n", TOS_NODE_ID);
		}
    else
    {
      int i;
			dbg(NEIGHBOR_CHANNEL, "UPDATED NEIGHBORHOOD.\nMembers: %d Node ID: %d\n", call Neighborhood.size(), TOS_NODE_ID);
			for(i = 0; i < call Neighborhood.size(); i++)
      {
				dbg(NEIGHBOR_CHANNEL, "Neighbor: %d\n", call Neighborhood.get(i));
			}
		}
  }
  //DISCOVER NEIGHBORS
  void discoverNeighbors()
  {
    dbg(NEIGHBOR_CHANNEL, "Searching for Neighbors...\n");

    //send out packet with PROTOCOL_PINGREPLY
    makePack(&sendPacket, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_PINGREPLY, -1, 0, PACKET_MAX_PAYLOAD_SIZE);
    call Sender.send(sendPacket, AM_BROADCAST_ADDR);
  }
}

//:am i flooding packets?
//?? (loading...)
//we dont have to do this because we are using an event based language.
//
/*  it would however look like the following: */
//CHECK: am i busy? -- IF (THIS.NODE is flooding packets to am_broadcast)
//  send message back to source (message to src)
//    saying (yo we're busy, hol' up)
//else -- if im free
//  send message back to source (message to src)
//    saying (yo we're ready)
//CHECK: else -- MESSAGE RECIEVED
//  call event message_t* Receive.receive(msg, payload, len)
//    ^will check if we are at destination
