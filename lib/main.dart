import 'package:flutter/material.dart';
import 'package:hnpwa_client/hnpwa_client.dart';
import 'package:rxdart/rxdart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(RxNewsBloc(NewsService(HnpwaClient()))),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final NewsBloc _newsBloc;

  const MyHomePage(this._newsBloc) : super();

  @override
  StatelessElement createElement() {
    _newsBloc.loadFeed();
    return super.createElement();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Test"),
      ),
      body: Container(
        child: StreamBuilder(
          initialData: Loading(),
          stream: _newsBloc.feed,
          builder: (BuildContext context, AsyncSnapshot<Result> snapshot) {
            switch (snapshot.data.runtimeType) {
              case Loading:
                return Text("Loading");
              case Error:
                return Text("Error");
              case Success:
                return ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return Text("${(snapshot.data as Success)._feed.items[index].title}");
                  },
                  itemCount: (snapshot.data as Success)._feed.items.length,
                );
              default:
                throw Exception("INVALID TyPE ${snapshot.data.runtimeType}");
            }
          },
        ),
      ),
    );
  }
}

abstract class NewsBloc {
  void loadFeed();

  Observable<Result> feed;
}

class RxNewsBloc extends NewsBloc {
  final NewsService _newsService;

  final BehaviorSubject<Result> _news = BehaviorSubject<Result>();

  RxNewsBloc(this._newsService);

  void loadFeed() {
    _newsService.news().listen(_onResult);
  }

  void _onResult(Result event) {
    _news.add(event);
  }

  Observable<Result> get feed => _news;
}

class NewsService {
  final HnpwaClient _hnpwaClient;

  NewsService(this._hnpwaClient);

  Stream<Result> news() async* {
    yield Loading();
    try {
      var feed = await _hnpwaClient.news();
      yield Success(feed);
    } catch (exception) {
      yield Error(exception);
    }
  }
}

abstract class Result {}

class Loading extends Result {}

class Success extends Result {
  final Feed _feed;

  Success(this._feed);
}

class Error extends Result {
  final Exception exception;

  Error(this.exception);
}
