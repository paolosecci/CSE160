/**
 * @author UCM ANDES Lab
 * $Author: abeltran2 $
 * $LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
 *
 */

#include "../../includes/socket.h"

configuration TransportC
{
   provides interface Transport;

   // Internal
   uses interface List<lspLink> as ConfirmedC;

}

implementation
{
    components TransportP;
    Transport = TransportP;
    TransportP.Confirmed = ConfirmedC;

    components new SimpleSendC(AM_PACK);
    TransportP.Sender -> SimpleSendC;

    components new ListC(socket_store_t, 10) as TempSocketsC;
    TransportP.TempSockets -> TempSocketsC;

    components new ListC(socket_store_t, 10) as SocketsC;
    TransportP.Sockets -> SocketsC;

    components new HashmapC(int, MAXNODES) as RoutingTableC;
    TransportP.RoutingTable -> RoutingTableC;
}
