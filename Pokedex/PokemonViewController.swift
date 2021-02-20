import UIKit

class PokemonViewController: UIViewController {
    var url: String!
    var caught: Bool!

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var type1Label: UILabel!
    @IBOutlet var type2Label: UILabel!
    @IBOutlet var catchButton: UIButton!
    @IBOutlet var pokemonImage: UIImageView!
    @IBOutlet var pokemonDescription: UITextView!
    @IBOutlet var descriptionLabel: UILabel!
    
    @IBAction func toggleCatch() {
        caught = UserDefaults.standard.bool(forKey: nameLabel.text!)
        
        if caught {
            catchButton.setTitle("Catch", for: .normal)
            UserDefaults.standard.set(false, forKey: nameLabel.text!)
        }
        else {
            catchButton.setTitle("Release", for: .normal)
            UserDefaults.standard.set(true, forKey: nameLabel.text!)
        }
    }

    func capitalize(text: String) -> String {
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        nameLabel.text = ""
        numberLabel.text = ""
        type1Label.text = ""
        type2Label.text = ""
        pokemonDescription.text = ""
        descriptionLabel.text = "Description"

        loadPokemon()
    }

    func loadPokemon() {
        URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
            guard let data = data else {
                return
            }

            do {
                let result = try JSONDecoder().decode(PokemonResult.self, from: data)
                DispatchQueue.main.async { [self] in
                    self.navigationItem.title = self.capitalize(text: result.name)
                    self.nameLabel.text = self.capitalize(text: result.name)
                    self.numberLabel.text = String(format: "#%03d", result.id)

                    for typeEntry in result.types {
                        if typeEntry.slot == 1 {
                            self.type1Label.text = typeEntry.type.name
                        }
                        else if typeEntry.slot == 2 {
                            self.type2Label.text = typeEntry.type.name
                        }
                    }
                    
                    URLSession.shared.dataTask(with: URL(string: "https://pokeapi.co/api/v2/pokemon-species/\(result.id)")!) { (data, response, error) in
                        guard let data = data else {
                            return
                        }
                        
                        do {
                            let description = try JSONDecoder().decode(PokemonSpecies.self, from: data)
                            DispatchQueue.main.async {
                                for flavorText in description.flavor_text_entries {
                                    if flavorText.language.name == "en" {
                                        self.pokemonDescription.text = flavorText.flavor_text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\u{0C}", with: " ")
                                        break
                                    }
                                }
                            }
                        }
                        catch let error {
                            print(error)
                        }
                    }.resume()
                    
                    caught = UserDefaults.standard.bool(forKey: nameLabel.text!)
                    if caught {
                        catchButton.setTitle("Release", for: .normal)
                    }
                    else {
                        catchButton.setTitle("Catch", for: .normal)
                    }
                    
                    if let imageData = try? Data(contentsOf: URL(string: result.sprites.front_default)!) {
                        if let image = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                pokemonImage.image = image
                            }
                        }
                    }
                }
            }
            catch let error {
                print(error)
            }
        }.resume()
    }
}
