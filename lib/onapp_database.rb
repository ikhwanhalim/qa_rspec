require 'helpers/curl'
require 'helpers/parser'

class OnappDataBase

  include Curl
  include Parser
  attr_reader :target_tbl_names

  def initialize
    puts 'Getting Database configuration'
    connection = $cp.ssh_connection
    result = connection.exec!("cat /onapp/interface/config/database.yml || echo error")
    if result.split("\n").last.include?("error")
      puts "Failed get database.yml - #{result}"
      raise("Failed get database.yml - #{result}")
    else
      result.split("\n").each do |r|
        @mdb = r.gsub(/^.* /, "") if r.include?("database")
        @mpass = r.gsub(/^.* /, "").gsub(/\'/, "").gsub(/\"/, "") if r.include?("password")
      end
    end
    connection.close
    puts "Database : #{@mdb}"
    puts "Password : #{@mpass}"
    @target_tbl_names = {'Pack' => 'packs',
                         'ImageTemplateGroup' => 'template_groups',
                         'RecipeGroup' => 'recipe_groups',
                         'EdgeGroup' => 'edge_groups'

    }
  end

  def mysql(query, show_in_log = false)
    connection = $cp.ssh_connection
    result = connection.exec!("mysql --password='#{@mpass}' #{@mdb} -e\"#{query}\" && echo done || echo error")
    if result.split("\n").last.include?("error")
      puts "Mysql request failed - #{result}"
      connection.close
      raise
      return result
    else
      (puts "Mysql #{query} has been run successfully") if show_in_log
      connection.close
      return result
    end
  end

  def select_user(login)
    result = mysql("select id from users where login = '#{login}'")
    if result
      sql_str = result.split("\n")
      sql_str.pop
      sql_str.shift
      return sql_str.first
    else
      raise("Cant select USER - #{result}")
      return false
    end

  end
  def select_hv(virt, distro, server_type)
    result = mysql("select id from hypervisors where hypervisor_type='#{virt}' and online=1 and enabled=1 and distro='#{distro}' and server_type='#{server_type}'and label not like '%fake%'")
    if result
      sql_str = result.split("\n")
      sql_str.pop
      sql_str.shift
      hvid = get_hv_max_free_mem(sql_str)
      puts "HV ID = #{hvid}"
      if hvid!=nil
        return hvid
      else
        raise("No available #{virt} on #{distro} HVs")
      end
    else
      raise("Cant select HV - #{result}")
      return false

    end
  end

  def get_hv_max_free_mem(hv_ids)
    return hv_ids.first if hv_ids.count < 2
    freemem = 0
    hvid = nil
    hv_ids.each do |hvs|
      result = get("hypervisors/#{hvs}")
      if status?
        hvhash = from_api(result)
        freem = hvhash[:total_memory].to_i - hvhash[:total_memory_allocated_by_vms].to_i
        if freem > freemem
          freemem = freem
          hvid = hvs
        end
      end
    end
    hvid
  end

  def template_exist(template_file_name)
    result = select_from_db("select id from hypervisors where hypervisor_type='#{virt}' and online=1 and enabled=1 and distro='#{distro}' and server_type='#{server_type}'")
  end
  def get_hv_for_migration(hv_id)
    result = mysql("select id from hypervisors where hypervisor_group_id=(select hypervisor_group_id from hypervisors where id=#{hv_id}) and online=1 and enabled=1 and id!=#{hv_id}")
    if result
      hv_id = last_from_db(result)
      puts "HV ID = #{hv_id}"
      return hv_id
    else

      return false
    end
  end

  def last_from_db(result)
    sql_str = result.split
    sql_str.pop
    sql_str.shift
    sql_str.last
  end

  # For testing base resources
  def get_target_id(target_type, type = '')
    tbl_name = @target_tbl_names[target_type]
    request = "select id from #{tbl_name} order by id limit 1"
    if tbl_name == 'packs'
      request = "select id from #{tbl_name} where type = '#{type}' order by id limit 1"
    end
    result = mysql(request)
    if result
      target_id = last_from_db(result)
      puts "target_id = #{target_id}"
      return target_id
    else
      return false
    end
  end
end
