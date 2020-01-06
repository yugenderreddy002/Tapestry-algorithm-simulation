defmodule Actors do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__,args)
  end

  def init(args) do
    i=Enum.map(0..15,fn(x)->nil end)
    k=Enum.map(0..7,fn(x)->i end)
    state=%{:nodeid=>args,:pid=>self(),:routingtable=>k,:hops=>0}
    {:ok,state}
  end

  def constructTable(pid,noOfNodes) do
    GenServer.cast(pid,{:constructtable,noOfNodes})
  end


    def sendmessages(pid,noOfReq,ppid)  do
      dpid=pid
      # IO.inspect ppid
      GenServer.cast(dpid,{:sendmessages,pid,noOfReq,ppid})
    end


  def handle_cast({:constructtable,noOfNodes},state) do
      # IO.inspect "IN handle handle_cast"
    # table = :ets.new(:table, [:named_table, :public])
    :ets.insert(:table,{Map.get(state,:nodeid),Map.get(state,:routingtable)})

    keys=Enum.map(1..noOfNodes,fn(x)->Registry.lookup(NodeHashes,x) end)
    values=Enum.map(keys,fn(x)->k=Enum.at(x,0)
                              {_,hashvalue}=k
                                hashvalue end)
     # IO.inspect values


    Enum.each(values,fn(x)->
    x2= Map.get(state,:nodeid)
    dex=Actors.resolve(x2)
      # IO.inspect dex
    level=Enum.find_index(0..7, fn i -> String.at(x,i) != String.at(x2,i) end)

    level=if level==nil do
    7
  else
    level

    end
    state_table=elem(Enum.at(:ets.lookup(:table, x2),0),1)
    # IO.inspect :ets.lookup(:table, x2)
    value=elem(Integer.parse(String.at(x,level),16),0)

    if Enum.at(Enum.at(state_table,level),value)==nil do
      # k=String.at(x,z+1)
      # index=elem(Integer.parse(k,16),0)
      answer=List.replace_at(Enum.at(state_table,level),value,x)

      state_table=List.replace_at(state_table,level,answer)

      # IO.inspect "HI"
      :ets.insert(:table,{x2,state_table})
    else
      x1=Enum.at(Enum.at(state_table,level),value)
      a=Actors.resolve(x)
      x2=Actors.resolve(x2)
      x1=Actors.resolve(x1)
      # IO.inspect x2
      d1=x2-x1
      d2=x2-a
      if d1<=d2 do
        state_table=List.replace_at(Enum.at(state_table,level),value,x1)
        :ets.insert(:table,{x2,state_table})

      else
        state_table=List.replace_at(Enum.at(state_table,level),value,x)
        :ets.insert(:table,{x2,state_table})
      end
    end
     end)
     x2= Map.get(state,:nodeid)
      state_table=elem(Enum.at(:ets.lookup(:table, x2),0),1)


#     # IO.inspect Enum.at(state_table,0)
    state=Map.get_and_update(state, :routingtable, fn current_value ->
  {current_value, state_table}
end)
  state=elem(state,1)
    {:noreply,state}

  end




  def handle_cast({:sendmessages,pid,noOfReq,ppid},state) do
    # IO.inspect  "IN handle cast of send messages"
    src=Map.get(state,:nodeid)
    nodenumber=resolve(src)
    srcpid=pid
    max=Registry.count(NodeHashes)
    range=Enum.map(1..max,fn(x)->x end)
    range=range--[nodenumber]
    for i<- 1..noOfReq do

      random_number=Enum.random(range)

      dest=Registry.lookup(NodeHashes,random_number)
      dest=elem(Enum.at(dest,0),1)
      # task=Task.async(fn(x)->finddest(src,dest,self(),0) end)
      # Task.await(task)
      tassk=Task.async(fn->finddest(src,dest,srcpid,ppid,0)end)
      
      Task.await(tassk)
      # # Process.sleep(1000)
      # IO.inspect Map.get(state,:hops)


    end
    {:noreply,state}

  end


  def finddest(src,dest,srcpid,ppid,hop) do
    #  IO.inspect "In findest"
    GenServer.cast(srcpid,{:finddest,src,dest,srcpid,ppid,hop})
  end






def handle_cast({:finddest,src,dest,srcpid,ppid,hop},state) do
  # IO.inspect "Im in finddest handle cast"

  level=Enum.find_index(0..7, fn i -> String.at(src,i) != String.at(dest,i) end)
  level=if level==nil do
    7
  else
    level

    end
  x=Map.get(state,:routingtable)
  value=elem(Integer.parse(String.at(dest,level),16),0)
  valueat=Enum.at(Enum.at(x,level),value)
  # # IO.inspect valueat
  # IO.puts("acs b-----------------#{valueat}cjvdvchv-----------#{dest}")
  if valueat==dest do
    send ppid,{:hopsfound,hop}
  else 
   newpid=elem(Enum.at(Registry.lookup(Hashespid,valueat),0),1)
   src=valueat
   hop=hop+1
   GenServer.cast(newpid,{:finddest,src,dest,srcpid,ppid,hop})
end

  {:noreply,state}
end


# def handle_call({:destinationfound,new_hop},_from,state) do
#   state=Map.get_and_update(state, :hops, fn current_value ->
#     {current_value, new_hop}
#   end)
#     state=elem(state,1)
#   {:reply,state}
# end

def handle_call({:getroutingtable},_from,state) do
  x=Map.get(state,:routingtable)
{:reply,x,state}
end




  def resolve(hashvalue) do
    count=Registry.count(NodeHashes)

    k=Enum.map(1..count, fn(x)->

      i=elem(Enum.at(Registry.lookup(NodeHashes,x),0),1)
      if i==hashvalue do
        x
      end

    end)
    k=Enum.uniq(k)
    k=k--[nil]
    req=Enum.at(k,0)
    req
    end





def handle_cast({:updatetable,newstring},state) do
  
  values=[newstring]


    Enum.each(values,fn(x)->
    x2= Map.get(state,:nodeid)

    level=Enum.find_index(0..7, fn i -> String.at(x,i) != String.at(x2,i) end)

    level=if level==nil do
    7
  else
    level

    end
    state_table=elem(Enum.at(:ets.lookup(:table, x2),0),1)
    # IO.inspect :ets.lookup(:table, x2)
    value=elem(Integer.parse(String.at(x,level),16),0)

    if Enum.at(Enum.at(state_table,level),value)==nil do
      # k=String.at(x,z+1)
      # index=elem(Integer.parse(k,16),0)
      answer=List.replace_at(Enum.at(state_table,level),value,x)

      state_table=List.replace_at(state_table,level,answer)

      # IO.inspect "HI"
      :ets.insert(:table,{x2,state_table})
    else
      x1=Enum.at(Enum.at(state_table,level),value)
      a=Actors.resolve(x)
      x2=Actors.resolve(x2)
      x1=Actors.resolve(x1)
      d1=x2-x1
      d2=x2-a
      if d1<=d2 do
        state_table=List.replace_at(Enum.at(state_table,level),value,x1)
        :ets.insert(:table,{x2,state_table})

      else
        state_table=List.replace_at(Enum.at(state_table,level),value,x)
        :ets.insert(:table,{x2,state_table})
      end
    end
     end)
     x2= Map.get(state,:nodeid)
      state_table=elem(Enum.at(:ets.lookup(:table, x2),0),1)


#     # IO.inspect Enum.at(state_table,0)
    state=Map.get_and_update(state, :routingtable, fn current_value ->
  {current_value, state_table}
end)
  state=elem(state,1)
    {:noreply,state}


end

end
