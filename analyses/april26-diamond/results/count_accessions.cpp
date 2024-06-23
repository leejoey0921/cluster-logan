#include <iostream>
#include <sstream>
#include <unordered_map>
#include <string>

struct AccessionCount {
    int palmcores_count = 0;
    int beetle_count = 0;
    int var_obelisk_count = 0;
    int var_deltavirus_count = 0;
    int var_osiris_count = 0;
    int papilloma_count = 0;
};

void processLine(const std::string& line, std::unordered_map<std::string, AccessionCount>& accession_map) {
    std::istringstream iss(line);
    std::string field;
    std::string accession;
    std::string category;

    // Read the first field for accession
    std::getline(iss, field, '\t');
    accession = field.substr(0, field.find('_'));

    // Skip to the sixth field
    for (int i = 0; i < 4; ++i) {
        std::getline(iss, field, '\t');
    }
    std::getline(iss, field, '\t');
    
    std::string::size_type pos = field.find_first_of("-_.");
    category = field.substr(0, pos);

    // Further check if category is var.*
    if (category == "var") {
        category = field.substr(0, field.find_first_of("-_.", pos + 1));
    }

    // Update the accession count based on the category
    if (category == "palmcores") {
        accession_map[accession].palmcores_count++;
    } else if (category == "beetle") {
        accession_map[accession].beetle_count++;
    } else if (category == "var.obelisk") {
        accession_map[accession].var_obelisk_count++;
    } else if (category == "var.Deltavirus") {
        accession_map[accession].var_deltavirus_count++;
    } else if (category == "var.Osiris") {
        accession_map[accession].var_osiris_count++;
    } else if (category == "papilloma") {
        accession_map[accession].papilloma_count++;
    }
}

int main() {
    std::unordered_map<std::string, AccessionCount> accession_map;
    std::string line;

    // Read from standard input (stdin)
    while (std::getline(std::cin, line)) {
        processLine(line, accession_map);
    }

    std::cout << "Accession,Palmcores Count,Beetle Count,var.obelisk Count,var.Deltavirus Count,var.Osiris Count,Papilloma Count" << std::endl;

    // Output the results
    for (const auto& entry : accession_map) {
        std::cout << entry.first << "," 
                  << entry.second.palmcores_count  << ","
                  << entry.second.beetle_count  <<","
                  << entry.second.var_obelisk_count  <<","
                  << entry.second.var_deltavirus_count <<","
                  << entry.second.var_osiris_count  <<","
                  << entry.second.papilloma_count
                  << std::endl;
    }

    return 0;
}

