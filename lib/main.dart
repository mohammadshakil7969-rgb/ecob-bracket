import 'package:flutter/material.dart';

void main() {
  runApp(const EcobBracketApp());
}

class EcobBracketApp extends StatelessWidget {
  const EcobBracketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECOB Tournament Bracket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F5B),
        ),
        useMaterial3: true,
      ),
      home: const BracketPage(),
    );
  }
}

class BracketPage extends StatefulWidget {
  const BracketPage({super.key});

  @override
  State<BracketPage> createState() => _BracketPageState();
}

class _BracketPageState extends State<BracketPage> {
  final List<TextEditingController> teams = List.generate(
    32,
    (i) => TextEditingController(text: 'Team ${i + 1}'),
  );

  // Round 0 = Round of 32, then R16, QF, SF, Final
  final List<List<int?>> winners = [
    List<int?>.filled(16, null),
    List<int?>.filled(8, null),
    List<int?>.filled(4, null),
    List<int?>.filled(2, null),
    List<int?>.filled(1, null),
  ];

  String teamName(int id) {
    if (id < 0 || id >= 32) return 'TBD';
    final name = teams[id].text.trim();
    return name.isEmpty ? 'Team ${id + 1}' : name;
  }

  int? teamAt(int round, int match, int slot) {
    if (round == 0) {
      return match * 2 + slot;
    }

    final winner = winners[round - 1][match * 2 + slot];
    if (winner == null) return null;

    return winner;
  }

  int? selectedTeam(int round, int match, int slot) {
    if (round == 0) return teamAt(round, match, slot);

    final previousMatch = match * 2 + slot;
    return winners[round - 1][previousMatch];
  }

  String displayTeam(int round, int match, int slot) {
    if (round == 0) {
      return teamName(match * 2 + slot);
    }

    final previousMatch = match * 2 + slot;
    final winner = winners[round - 1][previousMatch];

    if (winner == null) return 'TBD';
    return teamName(winner);
  }

  void chooseWinner(int round, int match, int slot) {
    final candidate = selectedTeam(round, match, slot);
    if (candidate == null) return;

    setState(() {
      winners[round][match] = candidate;

      // Clear all later rounds so old winners do not remain.
      for (int r = round + 1; r < winners.length; r++) {
        final affectedMatch = match ~/ (1 << (r - round));
        if (affectedMatch >= 0 && affectedMatch < winners[r].length) {
          winners[r][affectedMatch] = null;
        }
      }
    });
  }

  Widget teamTile(int round, int match, int slot) {
    final selected = selectedTeam(round, match, slot);
    final currentWinner = winners[round][match];
    final isWinner = selected != null && currentWinner == selected;

    return InkWell(
      onTap: () => chooseWinner(round, match, slot),
      child: Container(
        width: 142,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isWinner ? const Color(0xFFD3F9D8) : Colors.white,
          border: Border.all(
            color: isWinner ? Colors.green : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayTeam(round, match, slot),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isWinner)
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
      ),
    );
  }

  Widget matchCard(int round, int match) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          teamTile(round, match, 0),
          teamTile(round, match, 1),
        ],
      ),
    );
  }

  Widget bracketColumn(int round, String title) {
    final count = winners[round].length;

    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF087F5B),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          for (int i = 0; i < count; i++) matchCard(round, i),
        ],
      ),
    );
  }

  void editTeams() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Team Names'),
        content: SizedBox(
          width: 400,
          height: 420,
          child: ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: teams[index],
                decoration: InputDecoration(
                  labelText: 'Team ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void resetBracket() {
    setState(() {
      for (final round in winners) {
        for (int i = 0; i < round.length; i++) {
          round[i] = null;
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in teams) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ECOB BRACKET',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Edit team names',
            onPressed: editTeams,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Reset bracket',
            onPressed: resetBracket,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFE6FCF5),
            child: const Text(
              '32 TEAMS • KNOCKOUT TOURNAMENT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF087F5B),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Tap a team to select the match winner.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bracketColumn(0, 'ROUND OF 32'),
                  bracketColumn(1, 'ROUND OF 16'),
                  bracketColumn(2, 'QUARTER-FINAL'),
                  bracketColumn(3, 'SEMI-FINAL'),
                  bracketColumn(4, 'FINAL'),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF087F5B),
            child: Text(
              'CHAMPION: ${winners[4][0] == null ? 'TBD' : teamName(winners[4][0]!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
