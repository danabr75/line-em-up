module ProjectileCollisionThread

  def self.update window, projectile, args
    # Thread.exit if !projectile.inited
    # air_targets    = args[0]
    # ground_targets = args[1]
    result = projectile.hit_objects(*args)

    result[:graphical_effects].each do |effect|
      window.add_graphical_effects << effect
    end

    # window.remove_projectile_ids.push(projectile.id) if !results[:is_alive]
  end
end