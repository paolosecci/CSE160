/**
 * @author UCM ANDES Lab
 * $Author: abeltran2 $
 * $LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
 *
 */

#include "../../includes/socket.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#define MAX_NUM_OF_SOCKETS 10

module TransportP
{
   provides interface Transport;

   //Internal
   uses interface List<socket_store_t> as Sockets;
   uses interface List<socket_store_t> as TempSockets;
   uses interface SimpleSend as Sender;
   uses interface List<lspLink> as Confirmed;
   uses interface Hashmap<int> as RoutingTable;
}

implementation
{
    socket_t test;
    socket_addr_t SockStruct;

  command socket_t Transport.socket()
  {
    socket_t fd;
    socket_store_t SOC;
    if(call Sockets.size() < MAX_NUM_OF_SOCKETS)
    {
      SOC.fd = call Sockets.size();
      fd = call Sockets.size();
      call Sockets.pushback(SOC);
    }
    else
    {
      dbg(TRANSPORT_CHANNEL, "No Available Socket: return NULL\n");
      fd = NULL;
    }
    return fd;
  }

  command error_t Transport.bind(socket_t fd, socket_addr_t *addr)
  {
    socket_store_t SOC;
    socket_addr_t socAddr;
    error_t t;
    bool found = FALSE;
    while(!call Sockets.isEmpty())
    {
        SOC = call Sockets.front();
        call Sockets.popfront();
        if(SOC.fd == fd && !found)
        {
            socAddr.port = addr->port;
            socAddr.addr = addr->addr;
            SOC.dest = socAddr;
            found = TRUE;
            dbg(TRANSPORT_CHANNEL, "fd found...\naddr:%d\tport:%d\n", socAddr.addr, socAddr.port);
        }
        call TempSockets.pushfront(SOC);
    }
    while(!call TempSockets.isEmpty())
    {
        call Sockets.pushfront(call TempSockets.front());
        call TempSockets.popfront();
    }

    if(found) return t = SUCCESS;
    else      return t = FAIL;
  }

  command socket_t Transport.accept(socket_t fd)
  {
  }

  command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen)
  {
  }

  command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen)
  {
  }

  command error_t Transport.connect(socket_t fd, socket_addr_t* addr)
  {
    pack syn;
    syn.dest = addr->addr;
    syn.src = TOS_NODE_ID;
    syn.seq = 1;
    syn.TTL = MAX_TTL;
    syn.protocol = PROTOCOL_TCP;

    call Sender.send(syn, call RoutingTable.get(syn.dest));
  }

  command error_t Transport.close(socket_t fd)
  {
  }

  command error_t Transport.receive(pack* package)
  {
    /*

    //RCV
    uint8_t* lastByteRead;
    uint8_t* nextByteExpected;
    uint8_t* lastByteRcvd;
    uint8_t MAX_RCV_BUFFER = X;
    X = EWMA(RTT);

    //SEND
    uint8_t* lastByteWritten;
    uint8_t* lastByteAckd;
    uint8_t* lastByteSent;

    (lastByteSent - lastByteAckd <= AdvertisedWindow)
    {else: ERROR}//wtf is going on if this^ isn't true

    //shared s&r
    uint8_t AdvertisedWindow = MAX_RCV_BUFFER - ((nextByteExpected - 1) - lastByteRead);
    uint8_t EffectiveWindow = AdvertisedWindow - (lastByteSent - lastByteAckd);

    if(syn)
    {
      ack back
    }
    else if(ack)
    {
      advance lastByteAckd; kind of like pc++; but LBA++;
      updateWindowAd();//with newly advanced lastByteAckd;
      updateEffWindow();//calculate new effective window
      if(EWindow > 0)//effective window
      {
        //we can send more data soooooo...
        //send next queued item
        call Sender.send(lastByteSent)
      }

    }


    if(queue.size() > MAX_RCV_BUFFER)
    {
      stall();//tell sender to chill/slowdown
    }
    */
  }

  command error_t Transport.release(socket_t fd)
  {
  }

  command error_t Transport.listen(socket_t fd)
  {
    socket_store_t SOC;
    enum socket_state tempState;
    error_t t;
    bool found = FALSE;
    while(!call Sockets.isEmpty())
    {
        SOC = call Sockets.front();
        call Sockets.popfront();
        if(SOC.fd == fd && !found)
        {
          tempState = LISTEN;
          SOC.state = tempState;
          found = TRUE;
          dbg(TRANSPORT_CHANNEL, "fd found.\nchanging state to %d...\n", tempState);
        }
        call TempSockets.pushfront(SOC);
    }
    while(!call TempSockets.isEmpty())
    {
        call Sockets.pushfront(call TempSockets.front());
        call TempSockets.popfront();
    }

    if(found) return t = SUCCESS;
    else      return t = FAIL;
  }

}
