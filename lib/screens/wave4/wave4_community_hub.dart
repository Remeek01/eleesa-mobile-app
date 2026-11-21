import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

typedef W4Map = Map<String, dynamic>;

class Wave4CommunityHub extends StatefulWidget {
  final int initialTabIndex; // 0 = People, 1 = Store, 2 = Notices & Events
  final bool embeddedInBottomNav;
  final String userRole;
  final String userName;
  final String userLevel;
  final Color accentColor;

  const Wave4CommunityHub({
    super.key,
    this.initialTabIndex = 0,
    this.embeddedInBottomNav = false,
    this.userRole = 'student',
    this.userName = 'Maxwell Amoah',
    this.userLevel = '300',
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  State<Wave4CommunityHub> createState() => _Wave4CommunityHubState();
}

class _Wave4CommunityHubState extends State<Wave4CommunityHub>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://eleesa-backend.onrender.com';
  static const Color _bgObsidian = Color(0xFF0E1116);
  static const Color _cardSurface = Color(0xFF161A22);
  static const Color _borderStroke = Color(0xFF262C3A);

  late TabController _tabController;
  bool _loading = true;
  String _searchQuery = '';
  String _peopleFilter = 'ALL';
  String _storeCategory = 'ALL';

  List<W4Map> _people = [];
  List<W4Map> _storeItems = [];
  List<W4Map> _notices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadWave4();
  }

  @override
  void didUpdateWidget(covariant Wave4CommunityHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        widget.initialTabIndex >= 0 &&
        widget.initialTabIndex <= 2) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWave4() async {
    setState(() => _loading = true);
    try {
      final res = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/wave4/people')),
        http.get(Uri.parse('$_baseUrl/api/wave4/store')),
        http.get(Uri.parse('$_baseUrl/api/wave4/notices')),
      ]);
      final pJson = jsonDecode(res[0].body) as W4Map;
      final sJson = jsonDecode(res[1].body) as W4Map;
      final nJson = jsonDecode(res[2].body) as W4Map;
      if (!mounted) return;
      setState(() {
        _people = List<W4Map>.from(pJson['people'] ?? []);
        _storeItems = List<W4Map>.from(sJson['items'] ?? []);
        _notices = List<W4Map>.from(nJson['notices'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F2937),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final tabBar = TabBar(
      controller: _tabController,
      indicatorColor: accent,
      labelColor: accent,
      unselectedLabelColor: Colors.white60,
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      tabs: const [
        Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'People'),
        Tab(icon: Icon(Icons.storefront_outlined, size: 18), text: 'Jiji Store'),
        Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Notices'),
      ],
    );

    final bodyContent = _loading
        ? Center(child: CircularProgressIndicator(color: accent))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildPeopleTab(accent),
              _buildStoreTab(accent),
              _buildNoticesTab(accent),
            ],
          );

    if (widget.embeddedInBottomNav) {
      return Scaffold(
        backgroundColor: _bgObsidian,
        floatingActionButton: _tabController.index == 0
            ? null
            : FloatingActionButton.extended(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.add),
                label: Text(
                  _tabController.index == 1 ? 'Sell Item' : 'Post Notice',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: _tabController.index == 1 ? _openSellItemDialog : _openPostNoticeDialog,
              ),
        body: Column(
          children: [
            Container(color: _cardSurface, child: tabBar),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgObsidian,
      appBar: AppBar(
        backgroundColor: _bgObsidian,
        title: const Text('ELEESA Community & Store', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: accent), onPressed: _loadWave4),
        ],
        bottom: tabBar,
      ),
      floatingActionButton: _tabController.index == 0
          ? null
          : FloatingActionButton.extended(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: Text(
                _tabController.index == 1 ? 'Sell Item' : 'Post Notice',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: _tabController.index == 1 ? _openSellItemDialog : _openPostNoticeDialog,
            ),
      body: bodyContent,
    );
  }

  // ==================== 1. KNOW YOUR PEOPLE ====================
  Widget _buildPeopleTab(Color accent) {
    final q = _searchQuery.toLowerCase();
    final filtered = _people.where((p) {
      final matchesRole = _peopleFilter == 'ALL' || '${p['role_group']}'.toLowerCase() == _peopleFilter.toLowerCase();
      final matchesQuery = q.isEmpty ||
          '${p['full_name']}'.toLowerCase().contains(q) ||
          '${p['specialty_or_portfolio']}'.toLowerCase().contains(q) ||
          '${p['title_or_level']}'.toLowerCase().contains(q);
      return matchesRole && matchesQuery;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search students, executives, lecturers, or alumni...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: accent),
            filled: true,
            fillColor: _cardSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderStroke),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'Student', 'Executive', 'Lecturer', 'Alumni'].map((grp) {
              final sel = _peopleFilter == grp;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(grp == 'ALL' ? 'Everyone (${_people.length})' : grp),
                  selected: sel,
                  selectedColor: accent.withValues(alpha: 0.22),
                  backgroundColor: _cardSurface,
                  labelStyle: TextStyle(color: sel ? accent : Colors.white70, fontWeight: FontWeight.w600),
                  side: BorderSide(color: sel ? accent : _borderStroke),
                  onSelected: (_) => setState(() => _peopleFilter = grp),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ...filtered.map((person) {
          final name = '${person['full_name']}';
          final initials = name.isNotEmpty ? name[0].toUpperCase() : 'E';
          final group = '${person['role_group']}';
          final badgeColor = group == 'Lecturer'
              ? Colors.amberAccent
              : (group == 'Executive' ? Colors.greenAccent : (group == 'Alumni' ? Colors.purpleAccent : accent));
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderStroke),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: badgeColor.withValues(alpha: 0.18),
                  child: Text(initials, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                          ),
                          _chip(group, badgeColor),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${person['title_or_level']} • ${person['specialty_or_portfolio']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Text('${person['email']}  •  ${person['phone']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==================== 2. ELEESA STORE (JIJI STYLE) ====================
  Widget _buildStoreTab(Color accent) {
    final cats = ['ALL', 'Lab & Circuit Kits', 'Calculators', 'Textbooks', 'Safety & Apparel', 'Student Services'];
    final visible = _storeCategory == 'ALL'
        ? _storeItems
        : _storeItems.where((i) => '${i['category']}' == _storeCategory).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cats.map((cat) {
              final sel = _storeCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat == 'ALL' ? 'All Items (${_storeItems.length})' : cat),
                  selected: sel,
                  selectedColor: accent.withValues(alpha: 0.22),
                  backgroundColor: _cardSurface,
                  labelStyle: TextStyle(color: sel ? accent : Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
                  side: BorderSide(color: sel ? accent : _borderStroke),
                  onSelected: (_) => setState(() => _storeCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ...visible.map((item) {
          final isSold = '${item['status']}'.toLowerCase() == 'sold';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderStroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _chip('${item['category']}', accent),
                    const SizedBox(width: 8),
                    _chip('${item['condition']}', Colors.amberAccent),
                    const Spacer(),
                    Text(
                      'GHS ${item['price_ghs']}',
                      style: TextStyle(
                        color: isSold ? Colors.white38 : Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${item['title']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${item['description']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['seller_name']} (Lvl ${item['seller_level']}) • ${item['location']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent),
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.copy, size: 14),
                      label: Text('${item['seller_contact']}', style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${item['seller_contact']}'));
                        _snack('Copied ${item['seller_name']} phone number.');
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==================== 3. NOTICES & IEEE/GHIE EVENTS ====================
  Widget _buildNoticesTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: _notices.map((n) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderStroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _chip('${n['category']}', accent),
                  const Spacer(),
                  Text('${n['event_date']}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${n['title']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${n['body']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text('By ${n['posted_by']} • ${n['venue']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await http.post(Uri.parse('$_baseUrl/api/wave4/notices/${n['notice_id']}/rsvp'));
                      _snack('RSVP confirmed!');
                      _loadWave4();
                    },
                    icon: Icon(Icons.how_to_reg, size: 16, color: accent),
                    label: Text('RSVP (${n['rsvp_count']})', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _openSellItemDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController(text: 'Tarkwa Campus');
    final descCtrl = TextEditingController();
    String category = 'Lab & Circuit Kits';
    String condition = 'Neatly Used';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text('List Item on ELEESA Store', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleCtrl, 'Item Title (e.g. ESP32 Kit)'),
              _field(priceCtrl, 'Price in GHS (e.g. 180)'),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white),
                items: ['Lab & Circuit Kits', 'Calculators', 'Textbooks', 'Safety & Apparel', 'Student Services']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? category,
              ),
              DropdownButtonFormField<String>(
                initialValue: condition,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white),
                items: ['Brand New', 'Neatly Used', 'Service']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => condition = v ?? condition,
              ),
              _field(phoneCtrl, 'WhatsApp / Call Number'),
              _field(locCtrl, 'Hostel / Campus Location'),
              _field(descCtrl, 'Specs & Condition Details'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse('$_baseUrl/api/wave4/store'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'title': titleCtrl.text.trim(),
                  'category': category,
                  'price_ghs': double.tryParse(priceCtrl.text.trim()) ?? 0,
                  'condition': condition,
                  'location': locCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'seller_name': widget.userName,
                  'seller_contact': phoneCtrl.text.trim(),
                  'seller_level': widget.userLevel,
                }),
              );
              _snack('Listing published to ELEESA Store!');
              _loadWave4();
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _openPostNoticeDialog() {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: 'Dec 02, 2026 • 01:00 PM');
    final venueCtrl = TextEditingController(text: 'Faculty of Engineering Auditorium');
    final bodyCtrl = TextEditingController();
    String category = 'IEEE / GhIE Event';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text('Broadcast Notice or Event', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleCtrl, 'Announcement / Seminar Title'),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: _cardSurface,
                style: const TextStyle(color: Colors.white),
                items: ['IEEE / GhIE Event', 'Department Notice', 'Competition', 'Academic Alert']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? category,
              ),
              _field(dateCtrl, 'Date & Time'),
              _field(venueCtrl, 'Venue'),
              _field(bodyCtrl, 'Details'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await http.post(
                Uri.parse('$_baseUrl/api/wave4/notices'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'title': titleCtrl.text.trim(),
                  'category': category,
                  'event_date': dateCtrl.text.trim(),
                  'venue': venueCtrl.text.trim(),
                  'body': bodyCtrl.text.trim(),
                  'posted_by': widget.userName,
                  'poster_role': widget.userRole,
                }),
              );
              _snack('Notice broadcast to ELEESA Grid!');
              _loadWave4();
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: _bgObsidian,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderStroke),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}