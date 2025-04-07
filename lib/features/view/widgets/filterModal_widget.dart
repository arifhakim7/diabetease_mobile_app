import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterModalWidget extends StatefulWidget {
  final Function(int?) onRiskLevelChanged;
  final Function(double?) onRatingChanged;
  final Function(List<String>) onTagsChanged;

  const FilterModalWidget({
    Key? key,
    required this.onRiskLevelChanged,
    required this.onRatingChanged,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  _FilterModalWidgetState createState() => _FilterModalWidgetState();
}

class _FilterModalWidgetState extends State<FilterModalWidget> {
  int? _selectedRiskLevel;
  double? _selectedRating;
  List<String> _selectedTags = [];

  final List<String> _availableTags = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snacks",
    "Desserts",
    "Kidney-Friendly",
    "Vegan & Vegetarian",
    "Veggie-Rich",
    "Budget-Friendly",
    "Quich & Easy"
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRating = prefs.getDouble('selectedRating');
      _selectedTags = prefs.getStringList('selectedTags') ?? [];
      _selectedRiskLevel = prefs.getInt('selectedRiskLevel');
    });
  }

  Future<void> _saveSelectedRating(double? rating) async {
    final prefs = await SharedPreferences.getInstance();
    if (rating != null) {
      await prefs.setDouble('selectedRating', rating);
    } else {
      await prefs.remove('selectedRating');
    }
  }

  Future<void> _saveSelectedTags(List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedTags', tags);
  }

  Future<void> _saveSelectedRiskLevel(int? riskLevel) async {
    final prefs = await SharedPreferences.getInstance();
    if (riskLevel != null) {
      await prefs.setInt('selectedRiskLevel', riskLevel);
    } else {
      await prefs.remove('selectedRiskLevel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Risk Level Dropdown
          DropdownButtonFormField<int>(
            value: _selectedRiskLevel,
            decoration: InputDecoration(
              labelText: 'Risk Level',
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
            style: const TextStyle(color: Colors.black),
            items: const [
              DropdownMenuItem<int>(value: null, child: Text('All Levels')),
              DropdownMenuItem<int>(value: 1, child: Text('Low Risk')),
              DropdownMenuItem<int>(value: 2, child: Text('Medium Risk')),
              DropdownMenuItem<int>(value: 3, child: Text('High Risk')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRiskLevel = value;
              });
              _saveSelectedRiskLevel(value);
              widget.onRiskLevelChanged(value);
            },
          ),
          const SizedBox(height: 16),

          // Rating Dropdown
          DropdownButtonFormField<double>(
            value: _selectedRating,
            decoration: InputDecoration(
              labelText: 'Min Rating',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem<double>(value: null, child: Text('Any Rating')),
              DropdownMenuItem<double>(value: 4.0, child: Text('4.0+')),
              DropdownMenuItem<double>(value: 3.5, child: Text('3.5+')),
              DropdownMenuItem<double>(value: 3.0, child: Text('3.0+')),
              DropdownMenuItem<double>(value: 2.5, child: Text('2.5+')),
              DropdownMenuItem<double>(value: 2.0, child: Text('2.0+')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRating = value;
              });
              _saveSelectedRating(value);
              widget.onRatingChanged(value);
            },
          ),
          const SizedBox(height: 16),

          // Tags with Chips
          const Text(
            'Select Tags',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                selectedColor: Colors.blue.shade100,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                  _saveSelectedTags(_selectedTags);
                  widget.onTagsChanged(_selectedTags);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedRiskLevel = null;
                    _selectedRating = null;
                    _selectedTags.clear();
                  });
                  widget.onRiskLevelChanged(null);
                  widget.onRatingChanged(null);
                  widget.onTagsChanged([]);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
