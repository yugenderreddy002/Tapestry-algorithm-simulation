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
    IO.inspect  cids
    Enum.each(0..noOfNodes-1, fn(i)->
      x=Enum.at(cids,i)
      y=elem(Enum.at(Registry.lookup(NodeHashes,i+1),0),1)
      {:ok,_}=Registry.register(Hashespid,y,x)

    end)




    task=Task.async(fn ->Enum.each(cids,fn(x)->Actors.constructTable(x,noOfNodes) end)end)
    Task.await(task)
    ppid=self()
    IO.inspect "bbvchsdcvhvchsdcvghwvcgvgcvcgvcgwc"
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


end
