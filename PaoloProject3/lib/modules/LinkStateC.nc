// Configuration
#define AM_LinkState 62

configuration LinkStateC
{
  provides interface LinkState;
  uses interface List<pack> as NeighborListC;
  uses interface List<lspLink> as LspLinkC;
  uses interface Hashmap<int> as HashmapC;
}

implementation
{
  components LinkStateP;
  components new SimpleSendC(AM_NEIGHBOR);
  components new AMReceiverC(AM_NEIGHBOR);

  components new TimerMilliC() as LspTimer;
  LinkStateP.LspTimer -> LspTimer;

  components new TimerMilliC() as Dijkstra;
  LinkStateP.DijkstraTimer -> Dijkstra;

  LinkStateP.NeighborList = NeighborListC;

  components RandomC as Random;
  LinkStateP.Random -> Random;

  // External Wiring
  LinkState = LinkStateP.LinkState;

  LinkStateP.LspLinkList = LspLinkC;
  LinkStateP.RoutingTable = HashmapC;

  components FloodingC;
  LinkStateP.LSPSender -> FloodingC.LSPSender;
}
