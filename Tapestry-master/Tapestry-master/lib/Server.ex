defmodule Mainmodule do

  def main(args) do
    if List.first(args)=="" do
      IO.puts("Pease enter valid arguments")
  else
    table = :ets.new(:table, [:named_table, :public])
    noOfNodes=args |> Enum.at(0) |> String.to_integer
    noOfReq=args |> Enum.at(1) |> String.to_integer
    {:ok, _} = Registry.start_link(keys: :unique, name: NodeHashes)
    {:ok, _} = Registry.start_link(keys: :unique, name: Hashespid)
    {:ok,z}=CreateActors.start_link(noOfNodes)
    list=Supervisor.which_children(z)
    cids=Enum.map(list,fn(x)->{_,cid,_,_}=x
                                cid end)

    cids=Enum.reverse(cids)
    # IO.inspect  cids
    Enum.each(0..noOfNodes-1, fn(i)->
      x=Enum.at(cids,i)
      y=elem(Enum.at(Registry.lookup(NodeHashes,i+1),0),1)
      {:ok,_}=Registry.register(Hashespid,y,x)

    end)

    newcids=cids--[Enum.at(cids,noOfNodes-1)]




    task=Task.async(fn ->Enum.each(newcids,fn(x)->Actors.constructTable(x,noOfNodes-1) end)end)
    Task.await(task)
    
    dynamicNodeAddition(Enum.at(cids,noOfNodes-1),noOfNodes)
    
    
    
    
    
    ppid=self()
    # IO.inspect "bbvchsdcvhvchsdcvghwvcgvgcvcgvcgwc"
      # task1=Task.async(fn->Enum.each(cids,fn(x)->Actors.sendmessages(x,noOfReq,ppid) end)end)
      # Task.await(task1)
# Actors.sendmessages(x,noOfReq,self())
Enum.each(cids,fn(x)->Actors.sendmessages(x,noOfReq,ppid) end)
list=[]
convergeCheck(0,noOfReq*noOfNodes,list)



    end

  end

  def convergeCheck(n,nreq,hopValues) when n===nreq do
    maxHop = Enum.max(hopValues)
    IO.puts("Maximum hop value is #{maxHop}")
    nil # n represents number of nodes knowing the rumor
  end


  def convergeCheck(n,nreq,hopValues) when n>=0 do
    receive do
      {:hopsfound,hops} ->
        # pid = Process.whereis(String.to_atom(initNode))
        # IO.inspect pid
        # IO.inspect Process.alive?(pid)
        hopValues = hopValues ++ [hops]
        convergeCheck(n+1,nreq,hopValues)

    end
  end


def dynamicNodeAddition(incomingpid,noOfNodes) do
  Actors.constructTable(incomingpid,noOfNodes)
  newstring=elem(Enum.at(Registry.lookup(NodeHashes,noOfNodes),0),1)
  # IO.inspect newstring
  firstlist=Enum.map(1..noOfNodes-1,fn(x)->
    # IO.inspect Registry.lookup(NodeHashes,x)
    k=elem(Enum.at(Registry.lookup(NodeHashes,x),0),1)
    levels=Enum.find_index(0..7, fn i -> String.at(k,i) != String.at(newstring,i) end)
    levels
  end)
maxlevel=Enum.max(firstlist)

idlist=Enum.map(1..noOfNodes-1,fn(x)->
  k=elem(Enum.at(Registry.lookup(NodeHashes,x),0),1)
  levels=Enum.find_index(0..7, fn i -> String.at(k,i) != String.at(newstring,i) end)
  if levels==maxlevel do
    k
  end
end)
idlist=Enum.uniq(idlist)
idlist=idlist--[nil]
nearest=Enum.random(idlist)
reqpid=elem(Enum.at(Registry.lookup(Hashespid,nearest),0),1)
resultnodes=[reqpid]
matchednodes=nodesatlevel(maxlevel,resultnodes,0)
Enum.each(matchednodes,fn(x)-> GenServer.cast(x,{:updatetable,newstring}) end)

end


def nodesatlevel(maxlevel,resultnodes,index) do

  resultnodes = if length(resultnodes)!=index do
    list = Enum.slice(resultnodes, index-1, length(resultnodes)-index)
    temp = Enum.map(list,fn(x)->
      routingtable=GenServer.call(x,{:getroutingtable},1000000)
      temp2 = Enum.map(maxlevel..7,fn(l)->
        nodes = Enum.at(routingtable,l)
      end)
 

    end)
    temp = Enum.uniq(List.flatten(temp)) -- [nil]
    temp=Enum.map(temp,fn(x)-> 
     z= elem(Enum.at(Registry.lookup(Hashespid,x),0),1)
     z
    end)
    resultnodes = resultnodes ++ temp
    resultnodes = Enum.uniq(resultnodes)
    # IO.inspect resultNodes
    # IO.puts("#{length(resultNodes)} #{index}")
    nodesatlevel(maxlevel+1,resultnodes,index+1)
  else
    resultnodes
  end
  resultnodes
end

end
