~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
  default_release: :default,
  default_environment: :prod

environment :prod do
  set(vm_args: "rel/vm.args")
  set(include_erts: true)
  set(include_src: false)
  set(cookie: :"5F&U2RvKE>g<Q(.@ikNc}I/g3aH(AbNQkF0x};CGwvR*)4P8ka(V{wfz[[z`/sBy")

  set(
    config_providers: [
      {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/runtime.exs"]}
    ]
  )

  set(
    overlays: [
      {:copy, "rel/runtime.exs", "etc/runtime.exs"}
    ]
  )
end

release :push_gateway do
  set(version: current_version(:push_gateway))

  set(
    applications: [
      :runtime_tools
    ]
  )
end
