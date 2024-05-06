#include <iostream>
#include <fstream>
#include <unordered_map>
#include <string>
#include <vector>
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

using namespace std;

struct FastaEntry {
    string header;
    string sequence;
};

int main(int argc, char** argv) {
    if (argc != 3) {
        cerr << "Usage: " << argv[0] << " <input_filename> <suffix>" << endl;
        return 1;
    }

    string filename = argv[1];
    ifstream input(filename);
    if (!input.is_open()) {
        cerr << "Error opening file: " << filename << endl;
        return 1;
    }

    string suffix = argv[2];  // the index for output filenames

    unordered_map<string, vector<FastaEntry>> circle_map;
    string line, current_header, current_sequence, full_header ;

    // Read the FASTA file
    while (getline(input, line)) {
        if (line.empty()) continue;
        if (line[0] == '>') {  // New header line
            if (!current_header.empty()) {
                // Store the last sequence before starting a new one
                circle_map[current_header].push_back({full_header, current_sequence});
                current_sequence.clear();
            }
            size_t start = line.find("_circle_") + 8;
            size_t end = line.find(' ', start);
            current_header = line.substr(start, end - start);
            full_header = line;
        } else {
            current_sequence += line;
        }
    }

    // Don't forget to save the last sequence
    if (!current_header.empty()) {
        circle_map[current_header].push_back({full_header, current_sequence});
    }

    input.close();

    // Output files
    ofstream selfloops("results/selfloops."+suffix+".fa", ios::app);
    ofstream complex("results/complex."+suffix+".fa", ios::app);

    // Distribute sequences to appropriate files
    for (const auto& pair : circle_map) {
        if (pair.second.size() == 1) {
            selfloops <<  pair.second.front().header << "\n" << pair.second.front().sequence << "\n";
        } else {
            for (const auto& entry : pair.second) {
                complex <<  entry.header << "\n" << entry.sequence << "\n";
            }
        }
    }

    selfloops.close();
    complex.close();

    return 0;
}

