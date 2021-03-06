module ProjectileUpdateThread

  # def self.create_new window, projectile, args
  #   window  = args[0]
  #   mouse_x = args[1]
  #   mouse_y = args[2]
  #   player  = args[3]
  #   t = Thread.new(projectile, window, mouse_x, mouse_y, player) do |local_projectile, local_window, local_mouse_x, local_mouse_y, local_player|
  #     Thread.exit if !local_projectile.is_alive
  #     results = local_projectile.update(local_mouse_x, local_mouse_y, local_player)

  #     results[:graphical_effects].each do |effect|
  #       local_window.graphical_effects << effect
  #     end

  #     # local_window.projectiles.delete(local_projectile.id) if !local_projectile.is_alive
  #     # puts "PRE COUNT #{local_window.remove_projectile_ids.count}"
  #     # puts results
  #     # puts "PUSHING" if !results[:is_alive]
  #     local_window.remove_projectile_ids.push(local_projectile.id) if !results[:is_alive]
  #     # puts "POST COUNT #{local_window.remove_projectile_ids.count}"
  #     Thread.exit
  #   end
  #   return t
  # end

  def self.update window, projectile, args
    # Thread.exit if !projectile.inited
    if projectile.is_alive
      result = projectile.update(*args)
      window.remove_projectile_ids.push(projectile.id) if !result[:is_alive]
    else
      window.remove_projectile_ids.push(projectile.id)
    end
  end
  
end