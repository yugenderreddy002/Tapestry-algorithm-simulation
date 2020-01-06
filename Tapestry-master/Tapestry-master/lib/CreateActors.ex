defmodule CreateActors do
  use Supervisor

  def start_link(n) do
    Supervisor.start_link(__MODULE__,n)
  end

  def init(n)  do
    children=for i<- 1..n do
      stringindex=to_string(i)
      hash=:crypto.hash(:sha, stringindex) |> Base.encode16
      {:ok,_}=Registry.register(NodeHashes,i,hash)
      # {:ok,_}=Registry.register(Hashespid,i,hash)

      x=Registry.lookup(NodeHashes,i)
      # IO.inspect x
      # pid=self()
      # IO.inspect pid()
      worker(Actors,[hash],[id: "#{hash}"])

    end 
    supervise(children,strategy: :one_for_one)
  end

end
