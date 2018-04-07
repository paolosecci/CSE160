// Configuration
#define AM_NEIGHBOR 62

configuration NeighborDiscoveryC
{
  provides interface NeighborDiscovery;
  uses interface List<pack> as NeighborListC;
}

implementation
{
  components NeighborDiscoveryP;
  components new SimpleSendC(AM_NEIGHBOR);
  components new AMReceiverC(AM_NEIGHBOR);

  NeighborDiscoveryP.NeighborList = NeighborListC;

  components RandomC as Random;
  NeighborDiscoveryP.Random -> Random;

  // External Wiring
  NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

  components new TimerMilliC() as myTimerC; //create a new timer with alias “myTimerC”
  NeighborDiscoveryP.NeigborDiscoveryTimer -> myTimerC; //Wire the interface to the component

  components FloodingC;
  NeighborDiscoveryP.FloodSender -> FloodingC.FloodSender;
}
