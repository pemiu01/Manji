import 'package:flutter/material.dart';

import 'package:rxdart/rxdart.dart';

import 'package:kanji_dictionary/bloc/kanji_bloc.dart';
import 'components/kanji_grid_view.dart';
import 'components/kanji_list_view.dart';

class KanaDetailPage extends StatefulWidget {
  final String kana;
  final Yomikata yomikata;

  KanaDetailPage(this.kana, this.yomikata);

  @override
  State<StatefulWidget> createState() => KanaDetailPageState();
}

class KanaDetailPageState extends State<KanaDetailPage> {
  List<Kanji> kanjis = [];
  bool showGrid = false;
  bool showShadow = false;
  ScrollController gridScrollController = ScrollController();
  ScrollController listScrollController = ScrollController();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    kanjiBloc.findKanjiByKana(widget.kana, widget.yomikata).listen((kanji) {
      this.setState(() {
        kanjis.add(kanji);
      });
    });

//    scrollController.addListener(() {
//      if(scrollController.offset == scrollController.position.minScrollExtent){
//        setState(() {
//          showShadow = false;
//        });
//      }else{
//        setState(() {
//          showShadow = true;
//        });
//      }
//    });

    gridScrollController.addListener(() {
      if(this.mounted){
        if (gridScrollController.offset <= 0) {
          setState(() {
            showShadow = false;
          });
        } else {
          setState(() {
            showShadow = true;
          });
        }
      }
    });

    listScrollController.addListener(() {
      if(this.mounted){
        if (listScrollController.offset <= 0) {
          setState(() {
            showShadow = false;
          });
        } else {
          setState(() {
            showShadow = true;
          });
        }
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          elevation: 0,
          title: Container(),
          actions: <Widget>[
            AnimatedCrossFade(
              firstChild: IconButton(
                icon: Icon(
                  Icons.view_headline,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    showGrid = !showGrid;
                  });
                },
              ),
              secondChild: IconButton(
                icon: Icon(
                  Icons.view_comfy,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    showGrid = !showGrid;
                  });
                },
              ),
              crossFadeState: showGrid ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: Duration(milliseconds: 200),
            )
          ],
        ),
        body: Flex(
          direction: Axis.vertical,
          children: <Widget>[
            Align(
                alignment: Alignment.topCenter,
                child: Material(
                  color: Theme.of(context).primaryColor,
                  elevation: showShadow?8:0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 100,
                    child: Center(
                      child: Text(widget.kana, style: TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        //fontFamily: 'Ai'
                      ),),
                    ),
                  ),
                )),
            Expanded(
              child: AnimatedCrossFade(
                  firstChild: KanjiGridView(kanjis: kanjis, scrollController: gridScrollController,),
                  secondChild: KanjiListView(kanjis: kanjis, scrollController: listScrollController,),
                  crossFadeState: showGrid ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: Duration(milliseconds: 200)),
            )
          ],
        ));
  }
}