// Module
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#define MAXNODES 20

module LinkStateP
{
  provides interface LinkState;

  // Internal
  uses interface Timer<TMilli> as LspTimer;
  uses interface Timer<TMilli> as DijkstraTimer;
  uses interface SimpleSend as LSPSender;
  uses interface List<lspLink> as LspLinkList;
  uses interface List<pack> as NeighborList;

  uses interface Hashmap<int> as RoutingTable;
  uses interface Random as Random;
}

implementation
{
  pack sendPack;
  lspLink sendLSPL;
  uint16_t lspAge = 0;
  bool isValueInArray(uint8_t val, uint8_t *arr, uint8_t size);
  int makeGraph();
  void makePack(pack *Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

  command void LinkState.start()
  {
    // one shot timer and include random element to it.
    //dbg(GENERAL_CHANNEL, "Booted\n");
    call LspTimer.startPeriodic(80000 + (uint16_t)((call Random.rand16())%10000));
    call DijkstraTimer.startOneShot(90000 + (uint16_t)((call Random.rand16())%10000));
  }

  command void LinkState.printRoutingTable()
  {
    int i = 0;
    for(i = 1; i <= call RoutingTable.size(); i++)
    {
      dbg(GENERAL_CHANNEL, "Dest: %d \t firstHop: %d\n", i, call RoutingTable.get(i));
    }
  }

  command void LinkState.print()
  {
    if(call LspLinkList.size() > 0)
    {
      uint16_t lspLLsize = call LspLinkList.size();
      uint16_t i = 0;

      for(i = 0; i < lspLLsize; i++)
      {
        lspLink lsp =  call LspLinkList.get(i);
        dbg(ROUTING_CHANNEL,"Source:%d\tNeighbor:%d\tcost:%d\n",lsp.src,lsp.neighbor,lsp.cost);
      }
    }
    else
    {
      dbg(COMMAND_CHANNEL, "***0 LSP of node  %d!\n",TOS_NODE_ID);
    }

  }

  event void LspTimer.fired()
  {
    uint16_t neighborListSize = call NeighborList.size();
    uint16_t lspListSize = call LspLinkList.size();

    uint8_t neighborArray[neighborListSize];
    uint16_t i, j;
    bool alreadyLinked = FALSE;

    if(lspAge == MAX_NEIGHBOR_AGE)//if old neighbor, empty lsp list
    {
      //dbg(NEIGHBOR_CHANNEL,"removing neighbor of %d with Age %d \n",TOS_NODE_ID,neighborAge);
      lspAge = 0;
      for(i = 0; i < lspListSize; i++)
      {
        call LspLinkList.popfront();
      }
    }

    for(i = 0; i < neighborListSize; i++)
    {
        pack neighborNode = call NeighborList.get(i);

        //sendLSP->payload[i] = n.Node;
        for(j = 0; j < lspListSize; j++)
        {
          lspLink listedLSPL = call LspLinkList.get(j);
          if(listedLSPL.src == TOS_NODE_ID && listedLSPL.neighbor == neighborNode.src)
            alreadyLinked = TRUE;
        }
        if (!alreadyLinked)
        {
          //make LSPL
          sendLSPL.neighbor = neighborNode.src;
          sendLSPL.cost = 1;
          sendLSPL.src = TOS_NODE_ID;

          call LspLinkList.pushback(sendLSPL);//add to lspLink List
  	      call DijkstraTimer.startOneShot(90000 + (uint16_t)((call Random.rand16())%10000));
        }
        if(!isValueInArray(neighborNode.src, neighborArray, neighborListSize))
          neighborArray[i] = neighborNode.src;
    }
    makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKSTATE, neighborListSize, (uint8_t *) neighborArray, neighborListSize);
    call LSPSender.send(sendPack, AM_BROADCAST_ADDR);
    //  dbg(ROUTING_CHANNEL, "Sending LSPs\n");
  }

  bool isValueInArray(uint8_t val, uint8_t *array, uint8_t size)
  {
    int i;
    for (i = 0; i < size; i++)
    {
      if(array[i] == val)
        return TRUE;
    }
    return FALSE;
  }

  void makePack(pack *Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length)
  {
    Packet->src = src;
    Packet->dest = dest;
    Packet->TTL = TTL;
    Packet->seq = seq;
    Packet->protocol = protocol;
    memcpy(Packet->payload, payload, length);
  }

  //dijkstra
  event void DijkstraTimer.fired()
  {
    int nodesize[MAXNODES];
    int lspLLsize = call LspLinkList.size();
    int maxNode = MAXNODES;
    int i, j, nextHop, cost[maxNode][maxNode], distance[maxNode], predList[maxNode];
    int considered[maxNode], nodeCount, shortestDistance, nextNode;
    //pred[] stores the predecessor of each node
    //nodeCount = number of seen

    //create the cost matrix
    int startNode = TOS_NODE_ID;
    bool adjMatrix[maxNode][maxNode];

    //init adjMatrix to all FALSE
    for(i = 0; i < maxNode; i++)
    {
      for(j = 0; j < maxNode; j++)
      {
        adjMatrix[i][j] = FALSE;
      }
    }

    for(i = 0; i < lspLLsize; i++)
    {//set all listed LSPL to true
      lspLink listedLSPL = call LspLinkList.get(i);
      adjMatrix[listedLSPL.src][listedLSPL.neighbor] = TRUE;
    }

    //if spot on adjMatrix[][] is 0, cost to it is INFINITY
    //if spot on adjMatrix[][] is 1, cost to it is 1
    for(i = 0; i < maxNode; i++)
    {
      for(j = 0; j < maxNode; j++)
      {
        if (adjMatrix[i][j] == 0)
          cost[i][j] = INFINITY;
        else
          cost[i][j] = adjMatrix[i][j];
      }
    }

    //init pred[], distance[], and visited[]
    for(i = 0; i < maxNode; i++)
    {
      distance[i] = cost[startNode][i];
      predList[i] = startNode;
      considered[i] = 0;
    }
    distance[startNode] = 0;
    considered[startNode] = 1;
    nodeCount = 1;

    while(nodeCount < maxNode - 1)
    {//DJIKSTRA'S MAIN LOOP

      shortestDistance = INFINITY;
      //nextnode gives the node at minimum distance
      for(i = 0; i < maxNode; i++)
      {
        if(distance[i] <= shortestDistance && !considered[i])
        {
          shortestDistance = distance[i];
          nextNode = i;
        }
      }
      considered[nextNode] = 1;

      //check if a better path exists through nextnode
      for(i = 0; i < maxNode; i++)
      {
        if(!considered[i])
        {
          if(shortestDistance + cost[nextNode][i] < distance[i])
          {//new shortestDistance
            distance[i] = shortestDistance + cost[nextNode][i];
            predList[i] = nextNode;
          }
        }
      }
      nodeCount++;
    }

    for (i = 0; i < maxNode; i++)
    {
      nextHop = TOS_NODE_ID;
      if(distance[i] != INFINITY)
      {
        if(i != startNode)
        {
          j = i;
          do //
          {
            if (j != startNode)
              nextHop = j;
            j = predList[j];//hop back
          }
          while (j != startNode);
        }
        else
        {
          nextHop = startNode;
        }
        if (nextHop != 0 )
        {
          call RoutingTable.insert(i, nextHop);
        }
      }
    }

  }
}
