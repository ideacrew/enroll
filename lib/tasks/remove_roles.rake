namespace :role do
  desc "remove assister and cac roles from users"
  # Usage rake role:remove
  task :remove => [:environment] do
      users = [
        {
          "first_name": "Matthew",
          "last_name": "Valente",
          "email": "mvalente@cohdc.org",
          "role": "assister"
        },
        {
          "first_name": "Linda",
          "last_name": "Perkins",
          "email": "",
          "role": "assister",
          "hbx":19745957
        },
        {
          "first_name": "Linda",
          "last_name": "Perkins",
          "email": "",
          "role": "assister",
          "hbx":19757810
        },
        {
          "first_name": "Priscilla",
          "last_name": "Boswell",
          "email": "",
          "role": "assister",
          "hbx":19745958
        },
        {
          "first_name": "Thelma",
          "last_name": "James",
          "email": "",
          "role": "assister",
          "hbx":19745959
        },
        {
          "first_name": "Gary",
          "last_name": "Monroe",
          "email": "",
          "role": "assister",
          "hbx":19745960
        },
        {
          "first_name": "Cynthia",
          "last_name": "Morris",
          "email": "",
          "role": "assister",
          "hbx":19745961
        },
        {
          "first_name": "Matthew",
          "last_name": "Valente",
          "email": "",
          "role": "assister",
          "hbx":19745963
        },
        {
          "first_name": "Lakita",
          "last_name": "Matthews",
          "email": "",
          "role": "assister",
          "hbx": 19745964
        },
        {
          "first_name": "Charles",
          "last_name": "Taylor",
          "email": "",
          "role": "assister",
          "hbx":19745965
        },
        {
          "first_name": "Marco",
          "last_name": "Castro",
          "email": "",
          "role": "assister",
          "hbx":19745967
        },
        {
          "first_name": "Sandra",
          "last_name": "Sanchez",
          "email": "",
          "role": "assister",
          "hbx":19745970
        },
        {
          "first_name": "Monique",
          "last_name": "Williams",
          "email": "",
          "role": "assister",
          "hbx":19745976
        },
        {
          "first_name": "Curtis",
          "last_name": "Watkins",
          "email": "",
          "role": "assister",
          "hbx":19745970
        },
        {
          "first_name": "Stephanie",
          "last_name": "Thomas",
          "email": "sethomas@unityhealthcare.org",
          "role": "assister"
        },
        {
          "first_name": "Paul",
          "last_name": "Foster",
          "email": "pfoster@whitman-walker.org",
          "role": "assister"
        },
        {
          "first_name": "Roland",
          "last_name": "Gutierrez",
          "email": "rolandgutierrez3@gmail.com",
          "role": "assister"
        },
        {
          "first_name": "Sherry",
          "last_name": "Romero",
          "email": "",
          "role": "assister",
          "hbx":19756992
        },
        {
          "first_name": "Sherry",
          "last_name": "Romero",
          "email": "",
          "role": "assister",
          "hbx":19756993
        },
        {
          "first_name": "Scott",
          "last_name": "Massey",
          "email": "",
          "role": "cac",
          "hbx":19835087
        },
        {
          "first_name": "Faith",
          "last_name": "Hackett",
          "email": "",
          "role": "cac",
          "hbx":19825124
        },
        {
          "first_name": "barton",
          "last_name": "Wallace",
          "email": "",
          "role": "cac",
          "hbx":19835090
        },
        {
          "first_name": "Jenkins",
          "last_name": "Mary",
          "email": "mjgwen@yahoo.com",
          "role": "cac"
        },
        {
          "first_name": "Bria",
          "last_name": "Roberts",
          "email": "",
          "role": "cac",
          "hbx":19888695
        },
        {
          "first_name": "Andrea",
          "last_name": "Watkins",
          "email": "andrea.watkins@dc.gov",
          "role": "cac"
        },
        {
          "first_name": "Williams",
          "last_name": "Imani",
          "email": "",
          "role": "cac",
          "hbx":19799562
        },
        {
          "first_name": "LaShawn",
          "last_name": "Potts",
          "email": "lashawn.potts@dc.gov",
          "role": "cac"
        },
        {
          "first_name": "Gina",
          "last_name": "Brown",
          "email": "ginmabuend@yahoo.com",
          "role": "cac"
        },
        {
          "first_name": "Yuri",
          "last_name": "Almendarez",
          "email": "yuri.almendarez@dc.gov",
          "role": "cac"
        },
        {
          "first_name": "Faith",
          "last_name": "Hackett",
          "email": "",
          "role": "cac",
          "hbx":19835085
        },
        {
          "first_name": "Sherry",
          "last_name": "Mooring",
          "email": "",
          "role": "cac",
          "hbx":19835088
        },
        {
          "first_name": "Kayla",
          "last_name": "Thompson",
          "email": "",
          "role": "cac",
          "hbx":19835089
        },
        {
          "first_name": "Franklin",
          "last_name": "Nikia",
          "email": "",
          "role": "cac",
          "hbx":19799561
        },
        {
          "first_name": "Simmons",
          "last_name": "Dail",
          "email": "",
          "role": "cac",
          "hbx":19799564
        },
        {
          "first_name": "Cohen",
          "last_name": "Barry",
          "email": "",
          "role": "cac",
          "hbx":19799565
        },
        {
          "first_name": "Singletary",
          "last_name": "Keyvae",
          "email": "",
          "role": "cac",
          "hbx":19799566
        },
        {
          "first_name": "Longshaw",
          "last_name": "Derek",
          "email": "",
          "role": "cac",
          "hbx":19799567
        },
        {
          "first_name": "Bobbi",
          "last_name": "Felder",
          "email": "",
          "role": "cac",
          "hbx":19812162
        },
        {
          "first_name": "Siavonya",
          "last_name": "Youmans",
          "email": "",
          "role": "cac",
          "hbx":19812453
        },
        {
          "first_name": "Sherry",
          "last_name": "Buckner",
          "email": "",
          "role": "cac",
          "hbx":19875552
        },
        {
          "first_name": "Amy",
          "last_name": "C",
          "email": "",
          "role": "cac"
        },
        {
          "first_name": "Arlethia",
          "last_name": "C",
          "email": "",
          "role": "cac",
          "hbx":19743033
        },
        {
          "first_name": "Musa",
          "last_name": "M",
          "email": "",
          "role": "cac",
          "hbx":19743034
        },
        {
          "first_name": "Reginald",
          "last_name": "R",
          "email": "",
          "role": "cac",
          "hbx":19743036
        },
        {
          "first_name": "Tyisha",
          "last_name": "B",
          "email": "",
          "role": "cac",
          "hbx":19743037
        },
        {
          "first_name": "Josue",
          "last_name": "G",
          "email": "",
          "role": "cac",
          "hbx":19752771
        },
        {
          "first_name": "Josue",
          "last_name": "G",
          "email": "",
          "role": "cac",
          "hbx":19752773
        },
        {
          "first_name": "Alisa",
          "last_name": "G",
          "email": "",
          "role": "cac",
          "hbx":19743040
        },
        {
          "first_name": "DeJonte",
          "last_name": "H",
          "email": "dejonte.holt@dc.gove",
          "role": "cac"
        },
        {
          "first_name": "Sharde",
          "last_name": "L",
          "email": "shardelatney@yahoo.com",
          "role": "cac"
        },
        {
          "first_name": "Antoinette",
          "last_name": "L",
          "email": "",
          "role": "cac",
          "hbx":19743043
        },
        {
          "first_name": "Alecia",
          "last_name": "M",
          "email": "",
          "role": "cac",
          "hbx":19743044
        },
        {
          "first_name": "Alecia",
          "last_name": "M",
          "email": "",
          "role": "cac",
          "hbx":19752778
        },
        {
          "first_name": "Denora",
          "last_name": "W",
          "email": "",
          "role": "cac",
          "hbx":19752778
        },
        {
          "first_name": "Derrick",
          "last_name": "W",
          "email": "",
          "role": "cac",
          "hbx":19743046
        },
        {
          "first_name": "Lawanda",
          "last_name": "Y",
          "email": "",
          "role": "cac",
          "hbx":19743047
        },
        {
          "first_name": "Gitania",
          "last_name": "A",
          "email": "",
          "role": "cac",
          "hbx":19743049
        },
        {
          "first_name": "Kelsey",
          "last_name": "Fox",
          "email": "",
          "role": "cac",
          "hbx":19875554
        },
        {
          "first_name": "Felicia",
          "last_name": "Hollins",
          "email": "",
          "role": "cac",
          "hbx":19888698
        },
        {
          "first_name": "Keisa",
          "last_name": "Price",
          "email": "",
          "role": "cac",
          "hbx":19888699
        },
        {
          "first_name": "Keisa",
          "last_name": "Price",
          "email": "",
          "role": "cac",
          "hbx":19888715
        },
        {
          "first_name": "Abdul",
          "last_name": "Kargbo",
          "email": "akargbo@unityhealthcare.org",
          "role": "cac"
        },
        {
          "first_name": "Marleen",
          "last_name": "Aldana",
          "email": "",
          "role": "cac",
          "hbx":19745998
        },
        {
          "first_name": "Martha",
          "last_name": "Claros",
          "email": "",
          "role": "cac",
          "hbx":19745999
        },
        {
          "first_name": "Jamie",
          "last_name": "Bingner",
          "email": "jbingner@unityhealthcare.org",
          "role": "cac"
        },
        {
          "first_name": "Stacey",
          "last_name": "Everett",
          "email": "",
          "role": "cac",
          "hbx":19746006
        },
        {
          "first_name": "Dorothy",
          "last_name": "Johnson",
          "email": "",
          "role": "cac",
          "hbx":19746009
        },
        {
          "first_name": "Cynthia",
          "last_name": "Edmondson",
          "email": "",
          "role": "cac",
          "hbx":19746022
        },
        {
          "first_name": "Shirell",
          "last_name": "Simpson",
          "email": "",
          "role": "cac",
          "hbx":19746023
        },
        {
          "first_name": "Cassandra",
          "last_name": "Baker",
          "email": "",
          "role": "cac",
          "hbx":19746024
        },
        {
          "first_name": "Tina",
          "last_name": "Barjasteh",
          "email": "",
          "role": "cac",
          "hbx":19746025
        },
        {
          "first_name": "Chris",
          "last_name": "Wynkoop",
          "email": "",
          "role": "cac",
          "hbx":19746026
        },
        {
          "first_name": "Laura",
          "last_name": "Kirkpatrick",
          "email": "",
          "role": "cac",
          "hbx":19746027
        },
        {
          "first_name": "Racheli",
          "last_name": "Schoenburg",
          "email": "rs1567@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Pamela",
          "last_name": "Ontiveros",
          "email": "",
          "role": "cac",
          "hbx":19746029
        },
        {
          "first_name": "Sonia",
          "last_name": "Dickerson",
          "email": "sdickerson@mbihs.com",
          "role": "cac"
        },
        {
          "first_name": "Heidy",
          "last_name": "Cruz",
          "email": "",
          "role": "cac",
          "hbx":19746038
        },
        {
          "first_name": "Arlethia",
          "last_name": "C",
          "email": "",
          "role": "cac",
          "hbx":19752767
        },
        {
          "first_name": "Musa",
          "last_name": "M",
          "email": "",
          "role": "cac",
          "hbx":19752768
        },
        {
          "first_name": "Brandi",
          "last_name": "P",
          "email": "",
          "role": "cac",
          "hbx":19752769
        },
        {
          "first_name": "Reginald",
          "last_name": "R",
          "email": "",
          "role": "cac",
          "hbx":19752770
        },
        {
          "first_name": "Tyisha",
          "last_name": "B",
          "email": "",
          "role": "cac",
          "hbx":19743037
        },
        {
          "first_name": "Travis",
          "last_name": "C",
          "email": "",
          "role": "cac",
          "hbx":19752772
        },
        {
          "first_name": "Alisa",
          "last_name": "G",
          "email": "",
          "role": "cac",
          "hbx":19752774
        },
        {
          "first_name": "Denora",
          "last_name": "W",
          "email": "",
          "role": "cac",
          "hbx":19752779
        },
        {
          "first_name": "Derrick",
          "last_name": "W",
          "email": "",
          "role": "cac",
          "hbx":19752780
        },
        {
          "first_name": "Valerie",
          "last_name": "B",
          "email": "valariebell@hotmail.com",
          "role": "cac"
        },
        {
          "first_name": "Ashley",
          "last_name": "Gitania",
          "email": "",
          "role": "cac",
          "hbx":19799570
        },
        {
          "first_name": "Alex",
          "last_name": "Martinez",
          "email": "amartinez@whitman-walker.org",
          "role": "cac"
        },
        {
          "first_name": "Michael",
          "last_name": "Poulson",
          "email": "mrp89@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Stephanie",
          "last_name": "Wachs",
          "email": "slw96@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Stephanie",
          "last_name": "Wachs",
          "email": "",
          "role": "cac",
          "hbx":19757321
        },
        {
          "first_name": "Stephanie",
          "last_name": "Wachs",
          "email": "",
          "role": "cac",
          "hbx":19757322
        },
        {
          "first_name": "Katelyn",
          "last_name": "Klein",
          "email": "kha4@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Ana",
          "last_name": "Arriola",
          "email": "aa1530@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Katherine",
          "last_name": "Sullivan",
          "email": "krs112@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Sindhu",
          "last_name": "Prabakaran",
          "email": "sp1068@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Elizabeth",
          "last_name": "Horne",
          "email": "",
          "role": "cac",
          "hbx":19757327
        },
        {
          "first_name": "Claire",
          "last_name": "Alexanian",
          "email": "",
          "role": "cac",
          "hbx":19757328
        },
        {
          "first_name": "John",
          "last_name": "Fraker",
          "email": "jhf48@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Nilesh",
          "last_name": "Seshadri",
          "email": "",
          "role": "cac",
          "hbx":19757330
        },
        {
          "first_name": "Jhenya",
          "last_name": "Nahreini",
          "email": "jn671@georgetown.edu",
          "role": "cac"
        },
        {
          "first_name": "Madeleine",
          "last_name": "Byrd",
          "email": "",
          "role": "cac",
          "hbx":19757332
        },
        {
          "first_name": "Tenisha",
          "last_name": "Johnson",
          "email": "",
          "role": "cac",
          "hbx":19835086
        },
        {
          "first_name": "Gibbidon",
          "last_name": "Desiree",
          "email": "",
          "role": "cac",
          "hbx":19799568
        },
        {
          "first_name": "Carson",
          "last_name": "Antonio",
          "email": "",
          "role": "cac"
        },
        {
          "first_name": "Asia",
          "last_name": "Roye",
          "email": "",
          "role": "cac",
          "hbx":19875560
        },
        {
          "first_name": "Adam",
          "last_name": "Cort",
          "email": "",
          "role": "cac",
          "hbx":19888708
        },
        {
          "first_name": "Adam",
          "last_name": "Cort",
          "email": "",
          "role": "cac",
          "hbx":19888692
        },
        {
          "first_name": "Stacy",
          "last_name": "Ferguson",
          "email": "",
          "role": "cac"
        },
        {
          "first_name": "Ashley",
          "last_name": "Grant",
          "email": "",
          "role": "cac"
        },
        {
          "first_name": "Debbie",
          "last_name": "Bell",
          "email": "",
          "role": "cac",
          "hbx":19888694
        },
        {
          "first_name": "Tiera",
          "last_name": "Austin",
          "email": "",
          "role": "cac",
          "hbx":19888712
        },
        {
          "first_name": "Eugene",
          "last_name": "Smith",
          "email": "",
          "role": "cac",
          "hbx":19888713
        },
        {
          "first_name": "Ahmed",
          "last_name": "Garad",
          "email": "",
          "role": "cac"
        },
        {
          "first_name": "Tiffany",
          "last_name": "Contee",
          "email": "",
          "role": "cac",
          "hbx":19888709
        },
        {
          "first_name": "Patricia",
          "last_name": "Watkins-Bioh",
          "email": "",
          "role": "cac",
          "hbx":19888716
        },
        {
          "first_name": "Shiqurra",
          "last_name": "Wilkes",
          "email": "",
          "role": "cac",
          "hbx":19888717
        },
        {
          "first_name": "Yolanda",
          "last_name": "Teabout",
          "email": "",
          "role": "cac",
          "hbx":19888718
        },
        {
          "first_name": "Yuri",
          "last_name": "Almendarez",
          "email": "",
          "role": "cac",
          "hbx":19888720
        }
      ]

      users.each do |user|
        hbx = user[:hbx]
        email = user[:email]
        role = user[:role]
        if hbx.present?
          person = Person.where(hbx_id:hbx).first
          if role == "assister" && person.assister_role.present?
            person.assister_role.destroy
          elsif role == "cac" && person.csr_role.present?
            person.csr_role.destroy
          end
        elsif email.present?
          user = User.where(email:email).first
          if user.person.present?
            if role == "assister" && user.person.assister_role.present?
              user.person.assister_role.destroy
            elsif role == "cac" && user.person.csr_role.present?
              user.person.csr_role.destroy
            end
          end
    
        end
      end
      puts "Roles successfully removed."
    end
end

