_preprocess = (data, untyped_data, stats_data) ->
    map.leaf_regions = topojson.feature(data, data.objects.leaf_regions).features
    geometries = data.objects.leaf_regions.geometries

    ### parse paths into arrays, and extract the class of each leaf region ###
    map.leaf_regions.forEach (f) ->
        f.properties.path = JSON.parse(f.properties.path)
        f.properties.class = f.properties.path[f.properties.path.length-1]

    ### presimplify the topologies (compute the effective area (z) of each point) ###
    topojson.presimplify(data)
    topojson.presimplify(untyped_data)

    ### store all leaf_regions into the ontology tree, and store each node within the feature's properties ###
    map.leaf_regions.forEach (f) ->
        n = ontology.get_node_from_class(f.properties.class)
        n.leaf_region = f
        f.properties.node = n

    ### compute merged regions from leaf regions ###
    _merge = (n, depth) ->
        n.merged_region = topojson.merge(data, geometries.filter (g) -> g.properties.path.length > depth and g.properties.path[depth] is n.name)

        if n.children?
            n.children.forEach (c) -> _merge(c, depth+1)

    _merge(ontology.tree, 0)

    ### compute all region centroids ###
    ontology.nodes.forEach (n) ->
        [n.x, n.y] = path_generator.centroid n.merged_region

    ### compute all region areas ###
    ontology.nodes.forEach (n) ->
        n.area = path_generator.area n.merged_region

    ### create a stats index ###
    _stats = {}
    stats_data.forEach (s) -> _stats[s.class] = s

    ### add stats to each leaf region ###
    map.leaf_regions.forEach (f) ->
        f.properties.node.stats = _stats[f.properties.node.name]

        console.error "Class not found in statistics data: #{f.properties.node.name}" if not f.properties.node.stats?

    ### compute additional stats ###
    map.leaf_regions.forEach (f) ->
        f.properties.node.stats.triple_density = f.properties.node.stats.triple_count / f.properties.node.leaf_count
        f.properties.node.stats.obj_props_density = f.properties.node.stats.obj_props_count / f.properties.node.leaf_count
        f.properties.node.stats.data_props_density = f.properties.node.stats.data_props_count / f.properties.node.leaf_count

    ### define readable, plural, multiline labels for level one regions ###
    _readable_labels =
      'http://dbpedia.org/ontology/Place': ['Places']
      'http://dbpedia.org/ontology/Agent': ['Agents']
      'http://dbpedia.org/ontology/Event': ['Events']
      'http://dbpedia.org/ontology/Species': ['Species']
      'http://dbpedia.org/ontology/Work': ['Works']
      'http://dbpedia.org/ontology/SportsSeason': ['Sports', 'Seasons']
      'http://dbpedia.org/ontology/UnitOfWork': ['Units of', 'Work']
      'http://dbpedia.org/ontology/TopicalConcept': ['Topical', 'Concepts']
      'http://dbpedia.org/ontology/Biomolecule': ['Biomolecules']
      'http://dbpedia.org/ontology/Activity': ['Activities']
      'http://dbpedia.org/ontology/Food': ['Food']
      'http://dbpedia.org/ontology/MeanOfTransportation': ['Means of', 'Transportation']
      'http://dbpedia.org/ontology/Device': ['Devices']
      'http://dbpedia.org/ontology/CelestialBody': ['Celestial', 'Bodies']
      'http://dbpedia.org/ontology/ChemicalSubstance': ['Chemical', 'Substances']
      'http://dbpedia.org/ontology/Medicine': ['Medicine']
      'http://dbpedia.org/ontology/TimePeriod': ['Time', 'Periods']
      'http://dbpedia.org/ontology/Satellite': ['Satellites']
      'http://dbpedia.org/ontology/SportCompetitionResult': ['Sport', 'Competition', 'Results']
      'http://dbpedia.org/ontology/AnatomicalStructure': ['Anatomical', 'Structures']
      'http://dbpedia.org/ontology/GeneLocation': ['Gene', 'Locations']
      'http://dbpedia.org/ontology/CareerStation': ['Career', 'Stations']
      'http://dbpedia.org/ontology/PersonFunction': ['Person', 'Functions']
      'http://www.opengis.net/gml/_Feature': ['gml:feature']
      'http://dbpedia.org/ontology/Language': ['Languages']
      'http://dbpedia.org/ontology/Sales': ['Sales']
      'http://dbpedia.org/ontology/Drug': ['Drugs']
      'http://dbpedia.org/ontology/EthnicGroup': ['Ethnic', 'Groups']
      'http://dbpedia.org/ontology/Award': ['Awards']
      'http://dbpedia.org/ontology/Colour': ['Colours']
      'http://dbpedia.org/ontology/Holiday': ['Holidays']
      'http://dbpedia.org/ontology/Currency': ['Currencies']
      'http://dbpedia.org/ontology/SnookerWorldRanking': ['Snooker','World','Rankings']
      'http://dbpedia.org/ontology/Swarm': ['Swarms']
      'http://dbpedia.org/ontology/Competition': ['Competitions']
      'http://dbpedia.org/ontology/List': ['Lists']
      'http://dbpedia.org/ontology/Name': ['Names']
      'http://dbpedia.org/ontology/Diocese': ['Dioceses']
      'http://dbpedia.org/ontology/Village': ['Villages']
      'http://dbpedia.org/ontology/Town': ['Towns']
      'http://dbpedia.org/ontology/City': ['Cities']
      'http://dbpedia.org/ontology/Island': ['Islands']
      'http://dbpedia.org/ontology/Country': ['Countries']
      'http://dbpedia.org/ontology/Continent': ['Continents']
      'http://dbpedia.org/ontology/River': ['Rivers']
      'http://dbpedia.org/ontology/Canal': ['Canals']
      'http://dbpedia.org/ontology/Lake': ['Lakes']
      'http://dbpedia.org/ontology/Mountain': ['Mountains']
      'http://dbpedia.org/ontology/MountainRange': ['Mountain','Ranges']
      'http://dbpedia.org/ontology/Crater': ['Craters']
      'http://dbpedia.org/ontology/MountainPass': ['Mountain','Passes']
      'http://dbpedia.org/ontology/Volcano': ['Volcanoes']
      'http://dbpedia.org/ontology/Glacier': ['Glaciers']
      'http://dbpedia.org/ontology/Cave': ['Caves']
      'http://dbpedia.org/ontology/Valley': ['Valleys']
      'http://dbpedia.org/ontology/Road': ['Roads']
      'http://dbpedia.org/ontology/Bridge': ['Bridges']
      'http://dbpedia.org/ontology/RailwayLine': ['Railway','Lines']
      'http://dbpedia.org/ontology/RoadTunnel': ['Road','Tunnels']
      'http://dbpedia.org/ontology/RoadJunction': ['Road','Junctions']
      'http://dbpedia.org/ontology/RailwayTunnel': ['Railway','Tunnels']
      'http://dbpedia.org/ontology/WaterwayTunnel': ['Waterway','Tunnels']
      'http://dbpedia.org/ontology/RailwayStation': ['Railway','Stations']
      'http://dbpedia.org/ontology/Airport': ['Airports']
      'http://dbpedia.org/ontology/Dam': ['Dams']
      'http://dbpedia.org/ontology/PowerStation': ['Power','Stations']
      'http://dbpedia.org/ontology/LaunchPad': ['Launch','Pads']
      'http://dbpedia.org/ontology/HistoricBuilding': ['Historic','Buildings']
      'http://dbpedia.org/ontology/Museum': ['Museums']
      'http://dbpedia.org/ontology/ReligiousBuilding': ['Religious','Buildings']
      'http://dbpedia.org/ontology/Hospital': ['Hospitals']
      'http://dbpedia.org/ontology/ShoppingMall': ['Shopping','Malls']
      'http://dbpedia.org/ontology/Castle': ['Castles']
      'http://dbpedia.org/ontology/Restaurant': ['Restaurants']
      'http://dbpedia.org/ontology/Hotel': ['Hotels']
      'http://dbpedia.org/ontology/Prison': ['Prisons']
      'http://dbpedia.org/ontology/Skyscraper': ['Skyscrapers']
      'http://dbpedia.org/ontology/Lighthouse': ['Lighthouses']
      'http://dbpedia.org/ontology/Theatre': ['Theatres']
      'http://dbpedia.org/ontology/RollerCoaster': ['Roller','Coasters']
      'http://dbpedia.org/ontology/WaterRide': ['Water','Rides']
      'http://dbpedia.org/ontology/MilitaryStructure': ['Military','Structures']
      'http://dbpedia.org/ontology/Tunnel': ['Tunnels']
      'http://dbpedia.org/ontology/Racecourse': ['Racecourses']
      'http://dbpedia.org/ontology/Stadium': ['Stadiums']
      'http://dbpedia.org/ontology/GolfCourse': ['Golf','Courses']
      'http://dbpedia.org/ontology/CricketGround': ['Cricket','Grounds']
      'http://dbpedia.org/ontology/HistoricPlace': ['Historic','Places']
      'http://dbpedia.org/ontology/ProtectedArea': ['Protected','Areas']
      'http://dbpedia.org/ontology/Park': ['Parks']
      'http://dbpedia.org/ontology/WorldHeritageSite': ['World','Heritage','Sites']
      'http://dbpedia.org/ontology/SiteOfSpecialScientificInterest': ['Sites of Special','Scientific Interest']
      'http://dbpedia.org/ontology/SkiArea': ['Ski','Areas']
      'http://dbpedia.org/ontology/Garden': ['Gardens']
      'http://dbpedia.org/ontology/Monument': ['Monuments']
      'http://dbpedia.org/ontology/WineRegion': ['Wine','Regions']
      'http://dbpedia.org/ontology/NascarDriver': ['Nascar','Drivers']
      'http://dbpedia.org/ontology/FormulaOneRacer': ['Formula One','Racers']
      'http://dbpedia.org/ontology/SpeedwayRider': ['Speedway','Riders']
      'http://dbpedia.org/ontology/AmericanFootballPlayer': ['American','Football','Players']
      'http://dbpedia.org/ontology/SumoWrestler': ['Sumo','Wrestlers']
      'http://dbpedia.org/ontology/AmateurBoxer': ['Amateur','Boxers']
      'http://dbpedia.org/ontology/BeachVolleyballPlayer': ['Beach','Volleyball','Players']
      'http://dbpedia.org/ontology/SnookerChamp': ['Snooker','Champs']
      'http://dbpedia.org/ontology/SoccerPlayer': ['Soccer','Players']
      'http://dbpedia.org/ontology/BaseballPlayer': ['Baseball','Players']
      'http://dbpedia.org/ontology/IceHockeyPlayer': ['Ice Hockey','Players']
      'http://dbpedia.org/ontology/Cricketer': ['Cricketers']
      'http://dbpedia.org/ontology/RugbyPlayer': ['Rugby','Players']
      'http://dbpedia.org/ontology/BasketballPlayer': ['Basketball','Players']
      'http://dbpedia.org/ontology/AustralianRulesFootballPlayer': ['Australian Rules','Football Players']
      'http://dbpedia.org/ontology/Cyclist': ['Cyclists']
      'http://dbpedia.org/ontology/TennisPlayer': ['Tennis','Players']
      'http://dbpedia.org/ontology/Swimmer': ['Swimmers']
      'http://dbpedia.org/ontology/GaelicGamesPlayer': ['Gaelic','Games','Players']
      'http://dbpedia.org/ontology/FigureSkater': ['Figure','Skaters']
      'http://dbpedia.org/ontology/MartialArtist': ['Martial','Artists']
      'http://dbpedia.org/ontology/GolfPlayer': ['Golf','Players']
      'http://dbpedia.org/ontology/Skier': ['Skiers']
      'http://dbpedia.org/ontology/HandballPlayer': ['Handball','Players']
      'http://dbpedia.org/ontology/ChessPlayer': ['Chess','Players']
      'http://dbpedia.org/ontology/Gymnast': ['Gymnasts']
      'http://dbpedia.org/ontology/PokerPlayer': ['Poker','Players']
      'http://dbpedia.org/ontology/BadmintonPlayer': ['Badminton','Players']
      'http://dbpedia.org/ontology/Curler': ['Curlers']
      'http://dbpedia.org/ontology/Canoeist': ['Canoeists']
      'http://dbpedia.org/ontology/Jockey': ['Jockeys']
      'http://dbpedia.org/ontology/DartsPlayer': ['Darts','Players']
      'http://dbpedia.org/ontology/TableTennisPlayer': ['Table','Tennis','Player']
      'http://dbpedia.org/ontology/HorseRider': ['Horse','Riders']
      'http://dbpedia.org/ontology/SquashPlayer': ['Squash','Players']
      'http://dbpedia.org/ontology/LacrossePlayer': ['Lacrosse','Players']
      'http://dbpedia.org/ontology/Skater': ['Skaters']
      'http://dbpedia.org/ontology/NationalCollegiateAthleticAssociationAthlete': ['National Collegiate','Athletic Association','Athletes']
      'http://dbpedia.org/ontology/Rower': ['Rowers']
      'http://dbpedia.org/ontology/NetballPlayer': ['Netball','Players']
      'http://dbpedia.org/ontology/Bodybuilder': ['Bodybuilders']
      'http://dbpedia.org/ontology/Guitarist': ['Guitarists']
      'http://dbpedia.org/ontology/ClassicalMusicArtist': ['Classical Music','Artists']
      'http://dbpedia.org/ontology/AdultActor': ['Adult','Actors']
      'http://dbpedia.org/ontology/VoiceActor': ['Voice','Actors']
      'http://dbpedia.org/ontology/ScreenWriter': ['Screen','Writers']
      'http://dbpedia.org/ontology/Poet': ['Poets']
      'http://dbpedia.org/ontology/Painter': ['Painters']
      'http://dbpedia.org/ontology/ComicsCreator': ['Comics','Creators']
      'http://dbpedia.org/ontology/Comedian': ['Comedians']
      'http://dbpedia.org/ontology/FashionDesigner': ['Fashion','Designers']
      'http://dbpedia.org/ontology/Photographer': ['Photographers']
      'http://dbpedia.org/ontology/Baronet': ['Baronets']
      'http://dbpedia.org/ontology/AnimangaCharacter': ['Animanga','Characters']
      'http://dbpedia.org/ontology/SoapCharacter': ['Soap','Characters']
      'http://dbpedia.org/ontology/SportsTeamMember': ['Sports Team','Members']
      'http://dbpedia.org/ontology/SoccerManager': ['Soccer','Managers']
      'http://dbpedia.org/ontology/MemberOfParliament': ['Member of','Parliament']
      'http://dbpedia.org/ontology/Congressman': ['Congressmen']
      'http://dbpedia.org/ontology/Governor': ['Governors']
      'http://dbpedia.org/ontology/President': ['Presidents']
      'http://dbpedia.org/ontology/Mayor': ['Mayors']
      'http://dbpedia.org/ontology/PrimeMinister': ['Prime','Ministers']
      'http://dbpedia.org/ontology/Senator': ['Senators']
      'http://dbpedia.org/ontology/Chancellor': ['Chancellors']
      'http://dbpedia.org/ontology/CollegeCoach': ['College','Coaches']
      'http://dbpedia.org/ontology/AmericanFootballCoach': ['American','Football','Coaches']
      'http://dbpedia.org/ontology/VolleyballCoach': ['Volleyball','Coaches']
      'http://dbpedia.org/ontology/ChristianBishop': ['Christian','Bishops']
      'http://dbpedia.org/ontology/Saint': ['Saints']
      'http://dbpedia.org/ontology/Cardinal': ['Cardinals']
      'http://dbpedia.org/ontology/Pope': ['Popes']
      'http://dbpedia.org/ontology/Entomologist': ['Entomologists']
      'http://dbpedia.org/ontology/Medician': ['Medicians']
      'http://dbpedia.org/ontology/RadioHost': ['Radio','Hosts']
      'http://dbpedia.org/ontology/TelevisionHost': ['Television','Hosts']
      'http://dbpedia.org/ontology/Murderer': ['Murderers']
      'http://dbpedia.org/ontology/OfficeHolder': ['Office','Holders']
      'http://dbpedia.org/ontology/MilitaryPerson': ['Military','People']
      'http://dbpedia.org/ontology/Noble': ['Nobles']
      'http://dbpedia.org/ontology/Monarch': ['Monarchs']
      'http://dbpedia.org/ontology/Judge': ['Judges']
      'http://dbpedia.org/ontology/Architect': ['Architects']
      'http://dbpedia.org/ontology/BeautyQueen': ['Beauty','Queens']
      'http://dbpedia.org/ontology/Journalist': ['Journalists']
      'http://dbpedia.org/ontology/Philosopher': ['Philosophers']
      'http://dbpedia.org/ontology/Model': ['Models']
      'http://dbpedia.org/ontology/BusinessPerson': ['Business','People']
      'http://dbpedia.org/ontology/Economist': ['Economists']
      'http://dbpedia.org/ontology/MythologicalFigure': ['Mythological','Figures']
      'http://dbpedia.org/ontology/Engineer': ['Engineers']
      'http://dbpedia.org/ontology/Religious': ['Religious']
      'http://dbpedia.org/ontology/Historian': ['Historians']
      'http://dbpedia.org/ontology/Astronaut': ['Astronauts']
      'http://dbpedia.org/ontology/Ambassador': ['Ambassadors']
      'http://dbpedia.org/ontology/Chef': ['Chefs']
      'http://dbpedia.org/ontology/PlayboyPlaymate': ['Playboy','Playmates']
      'http://dbpedia.org/ontology/HorseTrainer': ['Horse','Trainers']
      'http://dbpedia.org/ontology/Band': ['Bands']
      'http://dbpedia.org/ontology/ComedyGroup': ['Comedy','Groups']
      'http://dbpedia.org/ontology/School': ['Schools']
      'http://dbpedia.org/ontology/University': ['Universities']
      'http://dbpedia.org/ontology/College': ['Colleges']
      'http://dbpedia.org/ontology/SoccerClub': ['Soccer','Clubs']
      'http://dbpedia.org/ontology/RugbyClub': ['Rugby','Clubs']
      'http://dbpedia.org/ontology/HockeyTeam': ['Hockey','Teams']
      'http://dbpedia.org/ontology/BasketballTeam': ['Basketball','Teams']
      'http://dbpedia.org/ontology/CricketTeam': ['Cricket','Teams']
      'http://dbpedia.org/ontology/BaseballTeam': ['Baseball','Teams']
      'http://dbpedia.org/ontology/AustralianFootballTeam': ['Australian','Football Teams']
      'http://dbpedia.org/ontology/HandballTeam': ['Handball','Teams']
      'http://dbpedia.org/ontology/CyclingTeam': ['Cycling','Teams']
      'http://dbpedia.org/ontology/FormulaOneTeam': ['Formula','One Teams']
      'http://dbpedia.org/ontology/SpeedwayTeam': ['Speedway','Teams']
      'http://dbpedia.org/ontology/AmericanFootballTeam': ['American','Football Teams']
      'http://dbpedia.org/ontology/CanadianFootballTeam': ['Canadian','Football Teams']
      'http://dbpedia.org/ontology/RadioStation': ['Radio','Stations']
      'http://dbpedia.org/ontology/TelevisionStation': ['Television','Stations']
      'http://dbpedia.org/ontology/BroadcastNetwork': ['Broadcast','Networks']
      'http://dbpedia.org/ontology/Airline': ['Airlines']
      'http://dbpedia.org/ontology/RecordLabel': ['Record','Labels']
      'http://dbpedia.org/ontology/BusCompany': ['Bus','Companies']
      'http://dbpedia.org/ontology/Publisher': ['Publishers']
      'http://dbpedia.org/ontology/LawFirm': ['Law','Firms']
      'http://dbpedia.org/ontology/Brewery': ['Breweries']
      'http://dbpedia.org/ontology/Winery': ['Wineries']
      'http://dbpedia.org/ontology/SoccerLeague': ['Soccer','Leagues']
      'http://dbpedia.org/ontology/RugbyLeague': ['Rugby','Leagues']
      'http://dbpedia.org/ontology/BasketballLeague': ['Basketball','Leagues']
      'http://dbpedia.org/ontology/IceHockeyLeague': ['Ice Hockey','Leagues']
      'http://dbpedia.org/ontology/BaseballLeague': ['Baseball','Leagues']
      'http://dbpedia.org/ontology/AmericanFootballLeague': ['American','Football','Leagues']
      'http://dbpedia.org/ontology/VolleyballLeague': ['Volleyball','Leagues']
      'http://dbpedia.org/ontology/LacrosseLeague': ['Lacrosse','Leagues']
      'http://dbpedia.org/ontology/HandballLeague': ['Handball','Leagues']
      'http://dbpedia.org/ontology/FieldHockeyLeague': ['Field','Hockey','Leagues']
      'http://dbpedia.org/ontology/InlineHockeyLeague': ['Inline','Hockey','Leagues']
      'http://dbpedia.org/ontology/MotorcycleRacingLeague': ['Motorcycle','Racing','Leagues']
      'http://dbpedia.org/ontology/SoftballLeague': ['Softball','Leagues']
      'http://dbpedia.org/ontology/PoloLeague': ['Polo','Leagues']
      'http://dbpedia.org/ontology/SpeedwayLeague': ['Speedway','Leagues']
      'http://dbpedia.org/ontology/GolfLeague': ['Golf','Leagues']
      'http://dbpedia.org/ontology/TennisLeague': ['Tennis','Leagues']
      'http://dbpedia.org/ontology/CricketLeague': ['Cricket','Leagues']
      'http://dbpedia.org/ontology/AutoRacingLeague': ['Auto Racing','Leagues']
      'http://dbpedia.org/ontology/CanadianFootballLeague': ['Canadian','Football','Leagues']
      'http://dbpedia.org/ontology/VideogamesLeague': ['Videogames','Leagues']
      'http://dbpedia.org/ontology/AustralianFootballLeague': ['Australian','Football Leagues']
      'http://dbpedia.org/ontology/CurlingLeague': ['Curling','Leagues']
      'http://dbpedia.org/ontology/BowlingLeague': ['Bowling','Leagues']
      'http://dbpedia.org/ontology/MixedMartialArtsLeague': ['Mixed Martial','Arts Leagues']
      'http://dbpedia.org/ontology/MilitaryUnit': ['Military','Units']
      'http://dbpedia.org/ontology/PoliticalParty': ['Political','Parties']
      'http://dbpedia.org/ontology/GovernmentAgency': ['Government','Agencies']
      'http://dbpedia.org/ontology/Non-ProfitOrganisation': ['Non-Profit','Organisations']
      'http://dbpedia.org/ontology/TradeUnion': ['Trade','Unions']
      'http://dbpedia.org/ontology/PublicTransitSystem': ['Public','Transit','Systems']
      'http://dbpedia.org/ontology/Legislature': ['Legislatures']
      'http://dbpedia.org/ontology/SoccerTournament': ['Soccer','Tournaments']
      'http://dbpedia.org/ontology/TennisTournament': ['Tennis','Tournaments']
      'http://dbpedia.org/ontology/GolfTournament': ['Golf','Tournaments']
      'http://dbpedia.org/ontology/WomensTennisAssociationTournament': ['Women\'s Tennis','Association Tournaments']
      'http://dbpedia.org/ontology/OlympicEvent': ['Olympic','Events']
      'http://dbpedia.org/ontology/HorseRace': ['Horse','Races']
      'http://dbpedia.org/ontology/CyclingRace': ['Cycling','Races']
      'http://dbpedia.org/ontology/FootballMatch': ['Football','Matches']
      'http://dbpedia.org/ontology/GrandPrix': ['Grands','Prix']
      'http://dbpedia.org/ontology/WrestlingEvent': ['Wrestling',' Events']
      'http://dbpedia.org/ontology/MixedMartialArtsEvent': ['Mixed Martial','Arts Events']
      'http://dbpedia.org/ontology/NationalFootballLeagueEvent': ['National Football','League Events']
      'http://dbpedia.org/ontology/MilitaryConflict': ['Military','Conflicts']
      'http://dbpedia.org/ontology/Election': ['Elections']
      'http://dbpedia.org/ontology/Convention': ['Conventions']
      'http://dbpedia.org/ontology/FilmFestival': ['Film','Festivals']
      'http://dbpedia.org/ontology/MusicFestival': ['Music','Festivals']
      'http://dbpedia.org/ontology/SpaceMission': ['Space','Missions']
      'http://dbpedia.org/ontology/SolarEclipse': ['Solar','Eclipses']
      'http://dbpedia.org/ontology/RaceHorse': ['Race','Horses']
      'http://dbpedia.org/ontology/Insect': ['Insects']
      'http://dbpedia.org/ontology/Mollusca': ['Mollusca']
      'http://dbpedia.org/ontology/Fish': ['Fishes']
      'http://dbpedia.org/ontology/Bird': ['Birds']
      'http://dbpedia.org/ontology/Amphibian': ['Amphibians']
      'http://dbpedia.org/ontology/Reptile': ['Reptiles']
      'http://dbpedia.org/ontology/Arachnid': ['Arachnids']
      'http://dbpedia.org/ontology/Crustacean': ['Crustaceans']
      'http://dbpedia.org/ontology/Grape': ['Grapes']
      'http://dbpedia.org/ontology/CultivatedVariety': ['Cultivated','Varieties']
      'http://dbpedia.org/ontology/Fern': ['Ferns']
      'http://dbpedia.org/ontology/Conifer': ['Conifers']
      'http://dbpedia.org/ontology/Moss': ['Mosses']
      'http://dbpedia.org/ontology/GreenAlga': ['Green','Algae']
      'http://dbpedia.org/ontology/Cycad': ['Cycads']
      'http://dbpedia.org/ontology/ClubMoss': ['Club','Mosses']
      'http://dbpedia.org/ontology/Gnetophytes': ['Gnetophytes']
      'http://dbpedia.org/ontology/Ginkgo': ['Ginkgos']
      'http://dbpedia.org/ontology/Fungus': ['Fungi']
      'http://dbpedia.org/ontology/Bacteria': ['Bacteria']
      'http://dbpedia.org/ontology/Archaea': ['Archaea']
      'http://dbpedia.org/ontology/Newspaper': ['Newspapers']
      'http://dbpedia.org/ontology/AcademicJournal': ['Academic','Journals']
      'http://dbpedia.org/ontology/Magazine': ['Magazines']
      'http://dbpedia.org/ontology/Novel': ['Novels']
      'http://dbpedia.org/ontology/Comics': ['Comics']
      'http://dbpedia.org/ontology/Play': ['Plays']
      'http://dbpedia.org/ontology/Poem': ['Poems']
      'http://dbpedia.org/ontology/EurovisionSongContestEntry': ['Eurovision','Song Contest','Entries']
      'http://dbpedia.org/ontology/Album': ['Albums']
      'http://dbpedia.org/ontology/Single': ['Singles']
      'http://dbpedia.org/ontology/ArtistDiscography': ['Artist','Discographies']
      'http://dbpedia.org/ontology/ClassicalMusicComposition': ['Classical Music','Compositions']
      'http://dbpedia.org/ontology/VideoGame': ['Video','Games']
      'http://dbpedia.org/ontology/ProgrammingLanguage': ['Programming','Languages']
      'http://dbpedia.org/ontology/Anime': ['Anime']
      'http://dbpedia.org/ontology/HollywoodCartoon': ['Hollywood','Cartoons']
      'http://dbpedia.org/ontology/BiologicalDatabase': ['Biological','Databases']
      'http://dbpedia.org/ontology/Film': ['Films']
      'http://dbpedia.org/ontology/TelevisionShow': ['Television','Shows']
      'http://dbpedia.org/ontology/TelevisionEpisode': ['Television','Episodes']
      'http://dbpedia.org/ontology/Artwork': ['Artworks']
      'http://dbpedia.org/ontology/Website': ['Websites']
      'http://dbpedia.org/ontology/TelevisionSeason': ['Television','Seasons']
      'http://dbpedia.org/ontology/Musical': ['Musicals']
      'http://dbpedia.org/ontology/RadioProgram': ['Radio','Programs']
      'http://dbpedia.org/ontology/NationalFootballLeagueSeason': ['National Football','League Seasons']
      'http://dbpedia.org/ontology/NCAATeamSeason': ['NCAA Team','Seasons']
      'http://dbpedia.org/ontology/SoccerClubSeason': ['Soccer Club','Seasons']
      'http://dbpedia.org/ontology/BaseballSeason': ['Baseball','Seasons']
      'http://dbpedia.org/ontology/MotorsportSeason': ['Motorsport','Seasons']
      'http://dbpedia.org/ontology/SupremeCourtOfTheUnitedStatesCase': ['Supreme Court of','the United States','Cases']
      'http://dbpedia.org/ontology/ResearchProject': ['Research','Projects']
      'http://dbpedia.org/ontology/MusicGenre': ['Music','Genres']
      'http://dbpedia.org/ontology/Fashion': ['Fashion']
      'http://dbpedia.org/ontology/HumanGene': ['Human','Genes']
      'http://dbpedia.org/ontology/MouseGene': ['Mouse','Genes']
      'http://dbpedia.org/ontology/Protein': ['Proteins']
      'http://dbpedia.org/ontology/Enzyme': ['Enzyme']
      'http://dbpedia.org/ontology/Game': ['Games']
      'http://dbpedia.org/ontology/Cheese': ['Cheese']
      'http://dbpedia.org/ontology/Ship': ['Ships']
      'http://dbpedia.org/ontology/Aircraft': ['Aircrafts']
      'http://dbpedia.org/ontology/Automobile': ['Automobiles']
      'http://dbpedia.org/ontology/Locomotive': ['Locomotives']
      'http://dbpedia.org/ontology/Train': ['Trains']
      'http://dbpedia.org/ontology/Motorcycle': ['Motorcycles']
      'http://dbpedia.org/ontology/Rocket': ['Rockets']
      'http://dbpedia.org/ontology/Spacecraft': ['Spacecrafts']
      'http://dbpedia.org/ontology/SpaceStation': ['Space','Stations']
      'http://dbpedia.org/ontology/SpaceShuttle': ['Space','Shuttles']
      'http://dbpedia.org/ontology/AutomobileEngine': ['Automobile','Engines']
      'http://dbpedia.org/ontology/Weapon': ['Weapons']
      'http://dbpedia.org/ontology/InformationAppliance': ['Information','Appliances']
      'http://dbpedia.org/ontology/Asteroid': ['Asteroids']
      'http://dbpedia.org/ontology/Planet': ['Planets']
      'http://dbpedia.org/ontology/Star': ['Stars']
      'http://dbpedia.org/ontology/Galaxy': ['Galaxies']
      'http://dbpedia.org/ontology/ChemicalCompound': ['Chemical','Compounds']
      'http://dbpedia.org/ontology/Mineral': ['Minerals']
      'http://dbpedia.org/ontology/Disease': ['Diseases']
      'http://dbpedia.org/ontology/GivenName': ['Given','Names']
      'http://dbpedia.org/ontology/Surname': ['Surnames']
      'http://dbpedia.org/ontology/Year': ['Years']
      'http://dbpedia.org/ontology/YearInSpaceflight': ['Years in','Spaceflight']
      'http://dbpedia.org/ontology/ArtificialSatellite': ['Artificial','Satellites']
      'http://dbpedia.org/ontology/OlympicResult': ['Olympic','Results']
      'http://dbpedia.org/ontology/Brain': ['Brains']
      'http://dbpedia.org/ontology/Bone': ['Bones']
      'http://dbpedia.org/ontology/Artery': ['Arteries']
      'http://dbpedia.org/ontology/Nerve': ['Nerve']
      'http://dbpedia.org/ontology/Muscle': ['Muscle']
      'http://dbpedia.org/ontology/Vein': ['Veins']
      'http://dbpedia.org/ontology/Ligament': ['Ligaments']
      'http://dbpedia.org/ontology/Embryology': ['Embryology']
      'http://dbpedia.org/ontology/Lymph': ['Lymph']
      'http://dbpedia.org/ontology/HumanGeneLocation': ['Human Gene','Locations']
      'http://dbpedia.org/ontology/MouseGeneLocation': ['Mouse Gene','Locations']

    ontology.levels[1].forEach (n) ->
        n.readable_label = _readable_labels[n.name]

    ontology.leaves.forEach (n) ->
        if n.depth > 1 and n.leaf_region?
          n.readable_label = _readable_labels[n.name]

_preprocess_selection = (selection) ->
    ### compute selection parent, if any ###
    if selection.path.length > 0
        selection.parent = ontology.get_node_from_class(selection.path[selection.path.length-1])
    else
        selection.parent = null

    ### compute cartesian coordinates ###
    [selection.x, selection.y] = _ij_to_xy(selection.i, selection.j, selection.parent?)

    ### extract relational links ###
    ### FIXME links to self are currently ignored ###
    selection.relations = []

    ### outgoing links ###
    selection.object_properties.outgoing.forEach (t) ->
        if 'i' of t and 'j' of t
            path = ontology.get_path(t.c)
            [ox, oy] = _ij_to_xy(t.i.value, t.j.value, path.length > 0)

            selection.relations.push {
                source: selection,
                predicate: t.p.value,
                target: {
                    uri: t.o.value,
                    i: t.i.value,
                    j: t.j.value,
                    x: ox,
                    y: oy,
                    parent: if path.length > 0 then ontology.get_node_from_class(path[path.length-1]) else null
                }
            }
        else
            console.error('Link to out-of-map entity: ' + t.o.value)

    ### incoming links ###
    selection.object_properties.incoming.forEach (t) ->
        if 'i' of t and 'j' of t
            path = ontology.get_path(t.c)
            [sx, sy] = _ij_to_xy(t.i.value, t.j.value, path.length > 0)

            selection.relations.push {
                source: {
                    uri: t.s.value,
                    i: t.i.value,
                    j: t.j.value,
                    x: sx,
                    y: sy,
                    parent: if path.length > 0 then ontology.get_node_from_class(path[path.length-1]) else null
                },
                predicate: t.p.value,
                target: selection
            }
        else
            console.error('Link from out-of-map entity: ' + t.s.value)

    ### pointers relative to current selection ###
    selection.relations.forEach (r) ->
        if r.source is selection
            r.start = r.source
            r.end = r.target
        else
            r.start = r.target
            r.end = r.source
