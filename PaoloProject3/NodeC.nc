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
#include "includes/lsp.h"

configuration NodeC
{
}

implementation
{
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new ListC(pack, 64) as NeighborListC;
    components new ListC(lspLink, 64) as LspLinkC;
    components new HashmapC(int, 300) as HashmapC;

    Node -> MainC.Boot;
    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components NeighborDiscoveryC;
    Node.NeighborDiscovery -> NeighborDiscoveryC;
    NeighborDiscoveryC.NeighborListC -> NeighborListC;
    LinkStateC.LspLinkC -> LspLinkC;

    components LinkStateC;
    Node.LinkState -> LinkStateC;
    Node.RoutingTable -> HashmapC;
    LinkStateC.NeighborListC -> NeighborListC;
    LinkStateC.HashmapC -> HashmapC;

    components FloodingC;
    Node.FloodSender -> FloodingC.FloodSender;
    Node.RouteSender -> FloodingC.RouteSender;
    FloodingC.LspLinkC -> LspLinkC;
    FloodingC.HashmapC -> HashmapC;

    components TransportC;
    Node.Transport -> TransportC;

}
