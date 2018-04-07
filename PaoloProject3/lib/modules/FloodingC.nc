// Configuration
#define AM_FLOODING 79

configuration FloodingC
{
  provides interface SimpleSend as LSPSender;
  provides interface SimpleSend as FloodSender;
  provides interface SimpleSend as RouteSender;
  uses interface List<lspLink> as LspLinkC;
  uses interface Hashmap<int> as HashmapC;
}

implementation
{
  components FloodingP;
  components new SimpleSendC(AM_FLOODING);
  components new AMReceiverC(AM_FLOODING);

  //Wire Internal Components
  FloodingP.InternalSender -> SimpleSendC;
  FloodingP.InternalReceiver -> AMReceiverC;
  FloodingP.LspLinkList = LspLinkC;
  FloodingP.RoutingTable = HashmapC;

  //External Interfaces
  components NeighborDiscoveryC;
  FloodingP.NeighborDiscovery -> NeighborDiscoveryC;

  FloodSender = FloodingP.FloodSender;
  LSPSender = FloodingP.LSPSender;
  RouteSender = FloodingP.RouteSender;

  components new ListC(pack, 64) as PacketListC;
  FloodingP.PacketList -> PacketListC;

}
