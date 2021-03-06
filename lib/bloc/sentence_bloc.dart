import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kanji_dictionary/resource/constants.dart';
import 'package:rxdart/rxdart.dart';

import 'package:kanji_dictionary/models/sentence.dart';
import 'package:kanji_dictionary/models/word.dart';
import 'package:kanji_dictionary/resource/repository.dart';

export 'package:kanji_dictionary/models/kanji.dart';
export 'package:kanji_dictionary/models/sentence.dart';
export 'package:kanji_dictionary/models/word.dart';

class SentenceBloc {
  final _sentencesFetcher = BehaviorSubject<List<Sentence>>();
  final _isFetchingFetcher = BehaviorSubject<bool>();

  List<Sentence> _sentences = <Sentence>[];
  List<String> _unloadedSentencesStr = List<String>();

  Stream<List<Sentence>> get sentences => _sentencesFetcher.stream;
  Stream<bool> get isFetching => _isFetchingFetcher.stream;

  bool _isFetching;

  ///Used for pagination.
  int _length;

  ///Used for pagination for fetching sentences from Jisho.org.
  int _currentPage;

  ///Used as a start point for a range of sentences.
  DocumentSnapshot lastDoc;

  ///Initialize [SentenceBloc] with [length] which defaults to 10 and is used for pagination.
  SentenceBloc({int length = 10})
      : _length = length,
        _currentPage = 0,
        _isFetching = false;

  ///Fetch sentences from Jisho.org by a word.
  void fetchSentencesByWords(String str) {
    _sentences.clear();
    _isFetching = true;
    _isFetchingFetcher.sink.add(_isFetching);

    repo.fetchSentencesByKanji(str).listen((sentence) {
      print('${sentence.text}');
      if (!_sentencesFetcher.isClosed) {
        _sentences.add(sentence);
        _sentencesFetcher.sink.add(_sentences);
      }
    }).onDone(() {
      _isFetching = false;
      _isFetchingFetcher.sink.add(_isFetching);

      _currentPage++;
    });
  }

  ///Fetch sentences from Jisho.org by a word.
  void fetchMoreSentencesByWordFromJisho(String str) {
    if (_isFetching != null && !_isFetching) {
      _isFetching = true;
      _isFetchingFetcher.sink.add(_isFetching);
      repo.fetchSentencesByKanji(str, currentPage: _currentPage).listen((sentence) {
        if (!_sentencesFetcher.isClosed) {
          _sentences.add(sentence);
          _sentencesFetcher.sink.add(_sentences);
        }
      }).onDone(() {
        print("========Done=======");
        _isFetching = null;
        _isFetchingFetcher.sink.add(_isFetching);

        _currentPage++;
      });
    }
  }

  ///Fetch sentences from Jisho.org by a kanji.
  void fetchSentencesByKanjiFromJisho(String kanjiStr) {
    _sentences.clear();
    repo.fetchSentencesByKanji(kanjiStr).listen((sentence) {
      if (!_sentencesFetcher.isClosed) {
        _sentences.add(sentence);
        _sentencesFetcher.sink.add(_sentences);
      }
    });
  }

  ///Fetch sentences from Firebase.
  void fetchSentencesByKanjiFromFirebase(String kanji) {
    assert(kanji.length == 1);
    _sentences.clear();
    var ref = FirebaseFirestore.instance.collection('sentences2').doc(kanji).collection(sentencesKey).orderBy(textKey).limit(_length);
    ref.get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var sentences = snapshot.docs.map((e) => Sentence.fromMap(e.data())).toList();
        _sentences.addAll(sentences);
        _sentencesFetcher.sink.add(_sentences);
        lastDoc = snapshot.docs.last;
      }
    });
  }

  ///Fetch more sentences from Firebase.
  void fetchMoreSentencesByKanji(String kanji) {
    var ref = FirebaseFirestore.instance.collection('sentences2').doc(kanji).collection(sentencesKey).orderBy(textKey)
      ..startAfterDocument(lastDoc).limit(_length);

    ref.get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var sentences = snapshot.docs.map((e) => Sentence.fromMap(e.data())).toList();
        _sentences.addAll(sentences);
        _sentencesFetcher.sink.add(_sentences);
        lastDoc = snapshot.docs.last;
      }
    });
  }

  ///Fetch sentences from Firebase.
  void fetchSentencesByWordFromFirebase(String word) {
    _sentences.clear();
    if (word.length > 1) {
      var ref = FirebaseFirestore.instance.collection('wordSentences').doc(word).collection(sentencesKey).orderBy(textKey).limit(_length);
      ref.get().then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          var sentences = snapshot.docs.map((e) => Sentence.fromMap(e.data())).toList();
          _sentences.addAll(sentences);
          _sentencesFetcher.sink.add(_sentences);
          lastDoc = snapshot.docs.last;
        }
      });
    } else {
      fetchSentencesByKanjiFromFirebase(word);
    }
  }

  ///Fetch more sentences from Firebase.
  void fetchMoreSentencesByWord(String word) {
    if (word.length > 1) {
      var ref = FirebaseFirestore.instance.collection('wordSentences').doc(word).collection(sentencesKey).orderBy(textKey)
        ..startAfterDocument(lastDoc).limit(_length);

      ref.get().then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          var sentences = snapshot.docs.map((e) => Sentence.fromMap(e.data())).toList();
          _sentences.addAll(sentences);
          _sentencesFetcher.sink.add(_sentences);
          lastDoc = snapshot.docs.last;
        }
      });
    } else {
      fetchMoreSentencesByKanji(word);
    }
  }

  ///Get a single sentence from the local database.
  void getSingleSentenceByKanji(String kanjiStr) async {
    var jsonStr = await repo.getSentencesJsonStringByKanji(kanjiStr);
    if (jsonStr != null) {
      var list = (jsonDecode(jsonStr) as List).cast<String>();
      //var sentences = list.sublist(0 + 10 * currentPortion, 10 + 10 * currentPortion).map((str) => Sentence.fromJsonString(str)).toList();
      var sentence = Sentence.fromMap(jsonDecode(list.first));

      _unloadedSentencesStr = list;

      _sentences.add(sentence);

      if (sentence != null && !_sentencesFetcher.isClosed) {
        _sentencesFetcher.sink.add(_sentences);
      }
    }
  }

  ///Get sentences from the local database.
  void getSentencesByKanji(String kanjiStr) async {
    var jsonStr = await repo.getSentencesJsonStringByKanji(kanjiStr);
    if (jsonStr != null) {
      var list = (jsonDecode(jsonStr) as List).cast<String>();
      //var sentences = list.sublist(0 + 10 * currentPortion, 10 + 10 * currentPortion).map((str) => Sentence.fromJsonString(str)).toList();
      var sentences = await jsonToSentences(list.sublist(0, list.length < 5 ? list.length : 5));

      list.removeRange(0, list.length < 5 ? list.length : 5);

      _unloadedSentencesStr = list;

      _sentences.addAll(sentences);

      if (sentences != null && !_sentencesFetcher.isClosed) {
        _sentencesFetcher.sink.add(_sentences);
      }
    } else {}
  }

  ///Get more sentences from the local database.
  void getMoreSentencesByKanji() async {
    var sentences = await jsonToSentences(_unloadedSentencesStr.sublist(0, _unloadedSentencesStr.length < 10 ? _unloadedSentencesStr.length : 10));

    _unloadedSentencesStr.removeRange(0, _unloadedSentencesStr.length < 10 ? _unloadedSentencesStr.length : 10);

    _sentences.addAll(sentences);

    if (sentences != null && !_sentencesFetcher.isClosed) {
      _sentencesFetcher.sink.add(_sentences);
    }
  }

  void resetSentencesFetcher() {
    _sentencesFetcher.drain();
    _sentences.clear();
    _unloadedSentencesStr.clear();
  }

  void dispose() {
    _sentencesFetcher.close();
    _isFetchingFetcher.close();
  }
}
