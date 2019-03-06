require_relative '../config/environment'

API_URL = "https://www.episodate.com/api/"


# how can we clear the terminal each time we go into a new menu??
# (prevent text clutter + spacing with empty puts lines)


class CLI
  attr_accessor :user, :title_search



  # FOR NOW: keep loaded User instance in @@user - available to all CLI methods
  # @@user = nil
  # def self.user
  #   @@user
  # end

  # FOR NOW: store current title search in @@title_search - use to re-search
  # by page number within get_array_of_tv_shows, elsif "pages > 1" option
  # @@title_search = ""
  # def self.title_search
  #   @@title_search
  # end


  def self.run
    self.welcome_message
  end



  def self.welcome_message
    puts "Welcome to the Show Randomizer!"
    puts "Here, you can select your favorite shows"
    puts "and generate playlists of random episodes"
    puts "from your favorites!"
    puts
    self.user_select
  end



  def self.user_select
    puts
    puts "Please enter a user name:"  # add: ", or press Enter to see a list of users:" ???
    user_input = STDIN.gets.chomp
    # check if string is empty, or only spaces (try the string.strip! method)
    self.create_or_load_profile(user_input)
  end



  def self.create_or_load_profile(user_input)
    # search User database by user_name = user_input
    # if record found, load profile
    # if no record found, .create new row for User table
    # =>  COME BACK TO THIS ONCE USER TABLE/DATABASE IS SET UP

    user_profile = User.find_by(name: user_input) #=> returns User instance

    if user_profile == nil
      # create a new User row with :name = user_input
      @user = User.create(name: user_input)

    else
      @user = user_profile
    end

    self.main_menu(@user)
  end



  def self.main_menu(user)
    puts
    puts
    puts "Welcome #{@user.name}!"   # check this interpolation once User class is built
    puts "Please select an option below:"
    puts
          # main menu options
    puts "1. Search shows by title" # expand to include genre, and network?
    puts "2. Show current list of favorite shows"
    puts "3. Generate playlist!"
    puts "4. Select different user"
    # puts "4. Show user statistics"
    puts "0. Quit"
    puts "1.5. Skip to method fetch_episodes_by_id, for The Simpsons (id# 6122)"
    user_input = STDIN.gets.chomp
    self.route_user_input(user_input)
  end



  def self.route_user_input(user_input)
    # build tree of user_input options here
    if user_input == "1"
      self.search_shows_by_title

    elsif user_input == "2"

    elsif user_input == "3"

    elsif user_input == "4"
      self.user_select

    elsif user_input == "0"
      puts "Thank you! Goodbye!"
      puts
      exit

    # easter egg / shortcut to: fetch_episodes_by_id
    elsif user_input == "1.5"
      self.fetch_episodes_by_id("6122")

    else
      puts "Invalid input. Please try again:"
      self.main_menu(self.user)
    end
  end



  def self.search_shows_by_title
    puts
    puts "Enter show title:"
    @title_search = STDIN.gets.chomp
    url = API_URL + "search?q=" + @title_search
    url.gsub!(" ", "%20")
    json = self.get_json(url) #=> receive Hash of search-result
    self.get_array_of_tv_shows(json)
  end



  def self.get_json(url)
    response = RestClient.get(url)
    json = JSON.parse(response.body) #=> json = hash, containing "page", "pages", "tv_shows" keys
  end



  def self.get_array_of_tv_shows(json)
    # check page numbers - if "pages" > 1, then iterate through each page (While? Until? Each?)
    # to grab correct array of shows
    all_pages = []

    if json["pages"] == 1
      all_pages = json["tv_shows"]

    elsif json["pages"] > 1
      counter = json["page"]
      counter_max = json["pages"]
      while counter <= counter_max
        url = API_URL + "search?q=" + @title_search + "&page=" + counter.to_s
        json = get_json(url)
        all_pages += json["tv_shows"]
        counter += 1
      end
      all_pages

    elsif json["pages"] == 0
      puts "No results found, please search again."
      self.search_shows_by_title

    else
      puts "ERROR: json[\"pages\"] returned a non-zero, non-positive number"
      puts "Returning to self.search_shows_by_title CLI class method."
      self.search_shows_by_title
    end
    self.search_results(all_pages)
  end


  def self.search_results(all_pages)
    formatted_list = []
    all_pages.each do |show_hash|
      formatted_list << "id. #{show_hash["id"]} - #{show_hash["name"]}"
    end
    self.print_search_results(formatted_list)
  end



  def self.print_search_results(formatted_list)
    puts
    puts "Search results (total count: #{formatted_list.count})"
    puts "=================================="
    puts formatted_list
    puts
    self.select_id_from_results
  end



  def self.select_id_from_results
    puts "Please enter the id number for the show you are looking for:"
    user_input = STDIN.gets.chomp
    url = API_URL + "show-details?q=" + user_input.to_s
    show_hash = self.get_json(url)["tvShow"] #=> hash of ONLY THE SPECIFIC show's details
    self.display_found_show_details(show_hash)
  end

  # now that we have the show details in a nice lil hash,
  # we can operate on it from a sub-menu:
  # 1. Show description
  # 2. Add to Favorites
  # 3. Search for another title
  # 4. Back to main menu

  def self.display_found_show_details(show_hash)
    puts
    puts "You have selected:"
    puts "=================="
    puts "Title: #{show_hash["name"]}"
    puts "Genre: #{show_hash["genres"][0]}"   # currently, only grabs first genre listed (in array)
    puts "Air Date: #{show_hash["start_date"]}"
    puts
    puts "What would you like to do?"
    puts "1. Show description"
    # puts "2. See list of episodes" #=> operate on show_hash["episodes"] while it's available?
    puts "2. Add to Favorites"
    puts "3. Search for another title"
    puts "4. Back to main menu"
    user_input = STDIN.gets.chomp
  end



  # ==========================
  # Isa's work - home, 3-5-19
  # ==========================


  def self.fetch_episodes_by_id(num)
    url = API_URL + "show-details?q=" + num
    episode_array = self.get_json(url)["tvShow"]["episodes"] #=> array of hash-episodes
    self.episode_menu(episode_array)
  end



  # the methods below demonstrate code that can be used to organize/collect
  # seasons and episode names in a formatted fashion.
  # use main_menu input "1.5" to skip to this part.
  # once comfortable with the organization of the data,
  # build a method to prepare strings for entry into the Playlist table
  # (individual episodes will be selected PRIOR to this formatting via a Randomizer)


  # this method is only for development - use it to test the outputs for the
  # season_list and title_list arrays below
  def self.episode_menu(episode_array)
    puts
    puts "List of Seasons:"
    puts "================"
    puts self.season_list(episode_array)
    puts
    puts "Please enter a season number:"
    user_input = STDIN.gets.chomp.
    # should printing the episode list happen in a different method??
    season_num = user_input.downcase!.tr("season", "").strip!.to_i
    puts
    puts self.title_list(episode_array, season_num)
  end



  # creates an array of formatted "Season #" strings - can be printed as a list
  def self.season_list(episode_array)
    episode_array.map do |episode_hash|
      "Season #{episode_hash["season"]}"
    end.uniq
  end


  # creates an array of formatted episode titles - modify to include S01e01 notation??
  def self.title_list(episode_array, season_num)
    title_array = []
    episode_array.each do |episode_hash|
      if episode_hash["season"] == season_num
        title_array << "#{episode_hash["episode"]}. #{episode_hash["name"]}"
      end
    end
    title_array
  end


end