/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC
{
}
implementation
{
    components MainC;
    components Node;
    Node -> MainC.Boot;

    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components ActiveMessageC;
    components new SimpleSendC(AM_PACK);
    components CommandHandlerC;
    Node.Receive -> GeneralReceive;
    Node.AMControl -> ActiveMessageC;
    Node.Sender -> SimpleSendC;
    Node.CommandHandler -> CommandHandlerC;

    components new TimerMilliC() as MyPeriodTimer;
    components RandomC as Random;
    Node.Timer1 -> MyPeriodTimer;
    Node.Random -> Random;

    components new ListC(Neighbor, 100) as MyNeighbors;
    components new ListC(Neighbor, 100) as MyDroppedNeighbors;
    components new ListC(SeenPack, 100) as MySeenPacks;
    Node.NeighborList -> MyNeighbors;
    Node.NeighborsDropped -> MyDroppedNeighbors;
    Node.SeenPacks -> MySeenPacks;

}
