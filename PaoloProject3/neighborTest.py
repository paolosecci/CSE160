from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("long_line.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);
    s.addChannel(s.NEIGHBOR_CHANNEL);
    s.addChannel("bitmap");

    # After sending a ping, simulate a little to prevent collision.

    s.runTime(30);
    print("\nALL MOTES ARE ON\n")
    s.neighborDMP(2);
    s.runTime(10);
    s.neighborDMP(4);
    s.runTime(10);
    
    s.moteOff(1);
    s.moteOff(3);
    s.runTime(10);

    print("\nNODE 6 and 4 is turned **OFF**. This should be removed from 8's neighbor list\n")
    s.neighborDMP(2);
    s.runTime(10);

    s.moteOn(6);
    s.runTime(150);

    print("\nNODE 6 is turned **ON**. This should be removed from 8's neighbor list\n")
    s.neighborDMP(4);
    s.runTime(10);


if __name__ == '__main__':
    main()
