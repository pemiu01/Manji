import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:kanji_dictionary/models/kanji.dart';
import 'package:kanji_dictionary/bloc/kanji_bloc.dart';
import 'package:kanji_dictionary/ui/components/kanji_list_view.dart';
import 'package:kanji_dictionary/ui/components/kanji_grid_view.dart';
import 'components/furigana_text.dart';

class JLPTKanjiPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => JLPTKanjiPageState();
}

class JLPTKanjiPageState extends State<JLPTKanjiPage> {
  //show gridview by default
  bool showGrid = true;
  bool sorted = true;
  bool altSorted = false;
  Map<JLPTLevel, List<Kanji>> jlptToKanjisMap = {
    JLPTLevel.n1: [],
    JLPTLevel.n2: [],
    JLPTLevel.n3: [],
    JLPTLevel.n4: [],
    JLPTLevel.n5: [],
  };

  @override
  void initState() {
    super.initState();

    for (var kanji in kanjiBloc.allKanjisList) {
      if (kanji.jlpt == 0) continue;
      jlptToKanjisMap[kanji.jlptLevel].add(kanji);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          //title: Text('日本語能力試験漢字'),
          title: FuriganaText(
            text: '日本語能力試験漢字',
            tokens: [
              Token(text: '日本語', furigana: 'にほんご'),
              Token(text: '能力', furigana: 'のうりょく'),
              Token(text: '試験', furigana: 'しけん'),
              Token(text: '漢字', furigana: 'かんじ')
            ],
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            IconButton(
                icon: AnimatedCrossFade(
                  firstChild: Icon(
                    FontAwesomeIcons.sortNumericDown,
                    color: Colors.white,
                  ),
                  secondChild: Icon(
                    FontAwesomeIcons.sortNumericDownAlt,
                    color: Colors.white,
                  ),
                  crossFadeState: altSorted ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: Duration(milliseconds: 200),
                ),
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    altSorted = !altSorted;
                  });
                }),
            IconButton(
              icon: AnimatedCrossFade(
                firstChild: Icon(
                  Icons.view_headline,
                  color: Colors.white,
                ),
                secondChild: Icon(
                  Icons.view_comfy,
                  color: Colors.white,
                ),
                crossFadeState: showGrid ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: Duration(milliseconds: 200),
              ),
              onPressed: () {
                setState(() {
                  showGrid = !showGrid;
                });
              },
            ),
          ],
          //elevation: 0,
          bottom: TabBar(tabs: [
            Tab(
              text: 'N5',
            ),
            Tab(
              text: 'N4',
            ),
            Tab(
              text: 'N3',
            ),
            Tab(
              text: 'N2',
            ),
            Tab(
              text: 'N1',
            ),
          ]),
        ),
        body: TabBarView(children: [
          buildTabBarViewChildren(JLPTLevel.n5),
          buildTabBarViewChildren(JLPTLevel.n4),
          buildTabBarViewChildren(JLPTLevel.n3),
          buildTabBarViewChildren(JLPTLevel.n2),
          buildTabBarViewChildren(JLPTLevel.n1),
        ]),
      ),
    );
  }

  Widget buildTabBarViewChildren(JLPTLevel jlptLevel) {
    if (sorted) {
      if (altSorted) {
        jlptToKanjisMap[jlptLevel].sort((l, r) => r.strokes.compareTo(l.strokes));
      } else {
        jlptToKanjisMap[jlptLevel].sort((l, r) => l.strokes.compareTo(r.strokes));
      }
    }
    return AnimatedCrossFade(
        firstChild: KanjiGridView(kanjis: jlptToKanjisMap[jlptLevel]),
        secondChild: KanjiListView(kanjis: jlptToKanjisMap[jlptLevel]),
        crossFadeState: showGrid ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        duration: Duration(milliseconds: 200));
  }
}

//class KanjiGridView extends StatelessWidget {
//  final List<Kanji> kanjis;
//
//  KanjiGridView({this.kanjis}) : assert(kanjis != null);
//
//  @override
//  Widget build(BuildContext context) {
//    return GridView.count(
//      crossAxisCount: 6,
//      children: kanjis.map((kanji) {
//        return Center(
//          child: InkWell(
//            child:Container(
//              width: double.infinity,
//              height: double.infinity,
//              child: Center(
//                child: Text(kanji.kanji, style: TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'kazei')),
//              )
//            ),
//            onTap: (){
//              Navigator.push(context, MaterialPageRoute(builder: (_)=>KanjiDetailPage(kanji: kanji)));
//            },
//          )
//        );
//      }).toList(),
//    );
//  }
//}