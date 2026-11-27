import 'package:flutter/material.dart';
import 'package:quickjobs/ekrani/jednostavni_ekran.dart';
import 'package:quickjobs/ekrani/glavni_ekran.dart';
import '../dekor.dart';
import 'opciUvjeti.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostavkeEkran extends StatelessWidget {
  final bool dolaziIzJednostavnog;
  const PostavkeEkran({super.key, this.dolaziIzJednostavnog = false});

  void _obrisiRacun(BuildContext context, QuickJobsColors boje) async {
    final supabase = Supabase.instance.client;

    bool? potvrda = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: boje.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              "Brisanje računa",
              style: TextStyle(color: boje.A, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Jeste li potpuno sigurni da želite obrisati svoj račun?\n\n"
          "Ova akcija je nepovratna i izbrisat će sve vaše podatke, oglase i recenzije.",
          style: TextStyle(color: boje.A?.withValues(alpha: 0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Odustani",
              style: TextStyle(
                color: boje.A?.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Briši račun",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (potvrda == true) {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) return;
        final userId = user.id;
        await supabase.rpc('potpuno_obrisi_korisnika');
        await supabase.auth.signOut();
        await supabase.from('profiles').delete().eq('id', userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vaš račun je uspješno i trajno obrisan."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } catch (e) {
        debugPrint("Greška pri brisanju računa: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Greška pri brisanju: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, boje),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  children: [
                    _buildPostavkeGrupa([
                      _PostavkaItem(
                        ikona: dolaziIzJednostavnog
                            ? Icons.dashboard_customize_rounded
                            : Icons.auto_awesome_motion_rounded,
                        naslov: dolaziIzJednostavnog
                            ? "Standardni način rada"
                            : "Jednostavan način rada",
                        boje: boje,
                        onTap: () async {
                          final supabase = Supabase.instance.client;
                          final user = supabase.auth.currentUser;

                          if (dolaziIzJednostavnog) {
                            // Prebacujemo na standardni (kandidat)
                            if (user != null) {
                              await supabase.auth.updateUser(
                                UserAttributes(data: {'uloga': 'kandidat'}),
                              );
                            }
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const glavni_ekran(),
                                ),
                                (route) => false,
                              );
                            }
                          } else {
                            // Prebacujemo na jednostavni (poslodavac)
                            if (user != null) {
                              await supabase.auth.updateUser(
                                UserAttributes(data: {'uloga': 'poslodavac'}),
                              );
                            }
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const JednostavniIzbornik(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                      _PostavkaItem(
                        ikona: Icons.description_outlined,
                        naslov: "Opći uvjeti korištenja",
                        boje: boje,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const UvjetiKoristenjaEkran(),
                            ),
                          );
                        },
                      ),
                      _PostavkaItem(
                        ikona: Icons.delete_forever_rounded,
                        naslov: "Obriši moj račun",
                        boje: boje,
                        onTap: () => _obrisiRacun(context, boje),
                        isZadnji: true,
                        bojaTeksta: const Color.fromARGB(255, 239, 28, 28),
                        bojaIkone: const Color.fromARGB(255, 242, 23, 23),
                      ),
                    ], boje),

                    const SizedBox(height: 25),

                    _buildPostavkeGrupa([
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeNotifier,
                        builder: (context, trenutniMode, _) {
                          final bool isDark =
                              trenutniMode == ThemeMode.dark ||
                              (trenutniMode == ThemeMode.system &&
                                  MediaQuery.platformBrightnessOf(context) ==
                                      Brightness.dark);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDark
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_rounded,
                                  color: boje.A,
                                  size: 24,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    isDark
                                        ? "Tamni način rada"
                                        : "Svijetli način rada",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: boje.A,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: isDark,
                                  activeColor: boje.A,
                                  activeTrackColor: boje.A?.withValues(
                                    alpha: 0.4,
                                  ),
                                  inactiveThumbColor: boje.A,
                                  inactiveTrackColor: boje.bg,
                                  onChanged: (val) {
                                    themeNotifier.value = val
                                        ? ThemeMode.dark
                                        : ThemeMode.light;
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _PostavkaItem(
                        ikona: Icons.grid_view_rounded,
                        naslov: "Broj oglasa po stranici",
                        boje: boje,
                        onTap: () {},
                      ),
                      _PostavkaItem(
                        ikona: Icons.format_size_rounded,
                        naslov: "Veličina fonta",
                        boje: boje,
                        onTap: () {},
                      ),
                      _PostavkaItem(
                        ikona: Icons.contrast_rounded,
                        naslov: "Visok kontrast",
                        boje: boje,
                        onTap: () {},
                      ),
                      _PostavkaItem(
                        ikona: Icons.check_box_outlined,
                        naslov: "Prihvaćene postavke",
                        boje: boje,
                        onTap: () {},
                        isZadnji: true,
                      ),
                    ], boje),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QuickJobsColors boje) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, size: 22, color: boje.A),
          ),
          Expanded(
            child: Text(
              "Postavke",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: boje.A,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPostavkeGrupa(List<Widget> items, QuickJobsColors boje) {
    return Container(
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: items),
    );
  }
}

class _PostavkaItem extends StatelessWidget {
  final IconData ikona;
  final String naslov;
  final VoidCallback onTap;
  final QuickJobsColors boje;
  final bool isZadnji;
  final Color? bojaTeksta;
  final Color? bojaIkone;

  const _PostavkaItem({
    required this.ikona,
    required this.naslov,
    required this.onTap,
    required this.boje,
    this.isZadnji = false,
    this.bojaTeksta,
    this.bojaIkone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Icon(ikona, color: bojaIkone ?? boje.A, size: 24),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    naslov,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: bojaTeksta ?? boje.A,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: boje.A?.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
        if (!isZadnji)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 20,
            color: boje.A?.withValues(alpha: 0.15),
          ),
      ],
    );
  }
}
