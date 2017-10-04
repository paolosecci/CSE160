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
    components new AMReceiverC(AM_PACK) as GeneralReceive;



    //CONNECTIONS paolo

    //connect timer
    components new TimerMilliC() as MyTimer;
    Node.PeriodTimer -> MyTimer;
    //connect random
    components RandomC as Random;
    Node.Random -> Random;
    //connect neighbor lists
    components new ListC(Neighbor*, 100) as MyNeighbors;
    Node.Neighborhood -> MyNeighbors;
    components new ListC(Neighbor*, 100) as MyDroppedNeighbors;
    Node.NeighborsDropped -> MyDroppedNeighbors;
    //connect check list
    components new ListC(uint32_t, 100) as MyCheckList;
    Node.CheckList -> MyCheckList;





    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;
}
