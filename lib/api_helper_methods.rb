def get_json(url)
  response = RestClient.get(url)
  json = JSON.parse(response.body) #=> json = hash, containing "page", "pages", "tv_shows" keys
end


## ========== OPTION 1. FROM USER MAIN MENU (cont.)========== ##
def search_results(all_pages)
  formatted_list = []
  all_pages.each do |show_hash|
    formatted_list << "id. #{show_hash["id"]} - #{show_hash["name"]}"
  end
  if formatted_list.count != 1
    self.print_search_results(formatted_list)
  else
    fetch_show_by_id(all_pages[0]["id"].to_s)
  end
end



def fetch_show_by_id(num)
  url = API_URL + "show-details?q=" + num
  show_hash = get_json(url)["tvShow"]
  self.display_found_show_details(show_hash)
end


## ========== OPTION 2. FROM USER MAIN MENU ========== ##
def print_list_of_favorites(user, menu)
  show_array = []
  favorites_array = []
  favorites_array = fetch_list_of_favorites(user)
  if favorites_array.count == 0
    system('clear')
    puts @menu_message
    puts
    puts "You have no favorites!"
    puts
    puts "Press enter to return to main menu and start adding shows!"
    STDIN.gets.chomp
    @menu_message = nil
    CLI.main_menu
  else
    favorites_array.each do |favorite_instance|
      show =  Show.find_by(api_id: favorite_instance.show_id)
      show_array << "id. #{show.api_id} - #{show.name}            (add to playlists: #{favorite_instance.playlist_on_off.upcase})"
    end
    system('clear')
    puts @menu_message
    puts
    puts "Here are your favorite shows!"
    puts "-----------------------------"
    puts show_array.sort
  end
  puts

  if menu == "main_menu"
    puts "Press enter to return to main menu or enter a show ID to remove from favorites"
    user_input = STDIN.gets.chomp
    selection = show_array.select do |show|
      show.include?(user_input)
    end
    if user_input.strip == ""
      @menu_message = nil
      CLI.main_menu
    elsif selection.count == 1
      delete_show_from_favorites(user_input, user)
    else
      @menu_message = "Please enter a valid show ID"
      print_list_of_favorites(user, "main_menu")
    end

  elsif menu == "profile_menu"
    puts "Enter a show's id number to turn adding episodes to playlists on or off."
    puts "Press enter when ready to return to your profile menu."
    user_input = STDIN.gets.chomp[0..5] #program crashes with integer strings longer than ~6 digits?!?
    if user_input.strip == ""
      @menu_message = nil
      puts
      puts "Profile loading, please wait..."
      user_profile_menu(user)

    else
      favorite = Favorite.where(show_id: user_input, user_id: user.id)[0]

      if favorite == nil
        @menu_message = "Please enter a valid show id"
        print_list_of_favorites(user, "profile_menu")

      else
        show_array.each do |show_name|
          if show_name.include?(user_input)

            if favorite.playlist_on_off == "on"
              favorite.playlist_on_off = "off"
              favorite.save
              @menu_message = nil
              print_list_of_favorites(user, "profile_menu")
            elsif favorite.playlist_on_off == "off"
              favorite.playlist_on_off = "on"
              favorite.save
              @menu_message = nil
              print_list_of_favorites(user, "profile_menu")
            end

          end

        end
        @menu_message = "Please enter a valid show id"
        print_list_of_favorites(user, "profile_menu")

      end
    end
  end

end



def delete_show_from_favorites(user_input, user)
  selected_show = Show.find_by(api_id: user_input)
  menu = "main_menu"
  if selected_show == nil
    @menu_message = "Please enter a valid show ID"
    print_list_of_favorites(user, menu)
  else
    Favorite.where(user_id: @user.id, show_id: selected_show.api_id).destroy_all
    @menu_message = "#{selected_show.name} has been removed from your Favorites"
    print_list_of_favorites(user,menu)
  end
end


## ========== OPTION 3. FROM USER MAIN MENU ========== ##
def fetch_episodes_for_playlist(user)
  all_episodes_array = []
  favorites_array = fetch_list_of_favorites(user)
  favorites_array.each do |favorite_instance|
    all_episodes_array += fetch_episodes_by_id(favorite_instance.show_id)
  end
  add_playlist_to_table(all_episodes_array, user)
end


def count_episodes_from_favorites(user)
  all_episodes_array = []
  favorites_array = fetch_list_of_favorites(user)
  favorites_array.each do |favorite_instance|
    all_episodes_array += fetch_episodes_by_id(favorite_instance.show_id)
  end
  all_episodes_array.count
end




def fetch_list_of_favorites(user)
  favorites_array = Favorite.where(user_id: user.id)
end


def filter_by_playlist_on_off(favorites_array)
  # if breaks, try:
  # array_output = ...
  favorites_array.select do |favorite_instance|
    favorite_instance.user_id == "on"
  end
  # ... return array_output
end


# THE METHOD BELOW SHOULD BE fetch_runtime_of_all_episodes INSTEAD!!
# def fetch_runtime_of_all_shows(user)
#   runtime_counter = 0
#   favorites_array = fetch_list_of_favorites(user)
#   favorites_array.each do |favorite_instance|
#     show = Show.find_by(api_id: favorite_instance.show_id)
#     runtime_counter += show.runtime
#   end
#   runtime_counter
# end



def sum_runtime_from_all_episodes(user)
  runtime_counter = 0
  all_episodes_array = []
  favorites_array = fetch_list_of_favorites(user)
  favorites_array.each do |favorite_instance|
    all_episodes_array += fetch_episodes_by_id(favorite_instance.show_id)
  end
  all_episodes_array.each do |episode_hash|
    runtime_counter += episode_hash["runtime"]
  end
  runtime_counter
end


def fetch_episodes_by_id(num)
  url = API_URL + "show-details?q=" + num.to_s
  show_info = get_json(url)["tvShow"]
  episode_array = show_info["episodes"] #=> array of hash-episodes
  episode_array.each do |episode_hash|
    episode_hash["show_name"] = show_info["name"]
    episode_hash["runtime"] = show_info["runtime"]
  end
  episode_array
end



def add_playlist_to_table(array, user)
  system('clear')
  puts "How many episodes would you like in your playlist?"
  ep_num = STDIN.gets.chomp.to_i
  random_array = array.sample(ep_num)
  episode_array = random_array.map do |episode_hash|
    "#{episode_hash["show_name"]} - S#{episode_hash["season"]}E#{episode_hash["episode"]}. #{episode_hash["name"]}"
  end
  playlist_instances = Playlist.where("user_id = ?", user.id)
  if playlist_instances.count == 0
    playlist_number = 1
  else
    playlist_number = playlist_instances.group("playlist_num").count.keys.count
    playlist_number += 1
  end
  i = 1
  episode_array.each do |episode|
    Playlist.create(user_id: user.id,
      playlist_num: playlist_number,
      ep_order: i,
      ep_desc: episode
    )
    i += 1
  end
  print_new_playlist(episode_array)
end



def print_new_playlist(episode_array)
  system('clear')
  puts "Playlist created!"
  puts "-----------------"
  puts episode_array
  puts
  puts "Press enter to return to the main menu"
  STDIN.gets.chomp
  CLI.main_menu
end



# plug into:
# CLI, #47 - self.user_select (add option to see list of users - will need to check if user_input == "")
# CLI, #78 - self.main_menu (add option to see list of users)
def list_all_users(menu)
  puts "All users currently in the system:"
  puts "=================================="
  puts User.pluck(:name)
  puts
  puts "Press enter to return to main menu."
  STDIN.gets.chomp
  if menu == "user_select_menu"
    self.user_select
  elsif menu == "main_menu"
    self.main_menu
  end
end




## ========== OPTION 1. FROM SHOW DETAILS (cont.) ========== ##
## ==========    referenced in add_to_favorites   ========== ##
def add_show_to_table(show_hash)
  show = Show.find_by(api_id: show_hash["id"])
  if show == nil
    Show.create(api_id: show_hash["id"], name: show_hash["name"], description: show_hash["description"], genre: show_hash["genres"][0], network: show_hash["network"], start_date: show_hash["start_date"], runtime: show_hash["runtime"])
  end
end
