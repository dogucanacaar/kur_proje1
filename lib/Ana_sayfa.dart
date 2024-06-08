import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Ana_sayfa extends StatefulWidget {
  @override
  State<Ana_sayfa> createState() => _Ana_sayfaState();
}

class _Ana_sayfaState extends State<Ana_sayfa> {
  Map<String, double> _oranlar = {};
  final String _baseUrl = "http://api.exchangeratesapi.io/v1/latest";
  final String _apiKey = "e4d8d85bbfcfe886f6a9f952574c27f4";
  double _sonuc = 0;
  String _secilenkur = "USD";
  TextEditingController _kontrol = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _veriCek();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Kur Dönüştürme Uygulaması"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kontrol,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (String yeniDeger) {
                        _hesapla();
                      },
                    ),
                  ),
                  SizedBox(width: 25),
                  DropdownButton<String>(
                    value: _secilenkur,
                    icon: Icon(Icons.arrow_downward),
                    items: _oranlar.keys.map((String kur) {
                      return DropdownMenuItem<String>(
                        value: kur,
                        child: Text(kur),
                      );
                    }).toList(),
                    onChanged: (String? yeniDeger) {
                      if (yeniDeger != null) {
                        setState(() {
                          _secilenkur = yeniDeger;
                        });
                        _hesapla();
                      }
                    },
                  )
                ],
              ),
              SizedBox(height: 20),
              Text(
                "${_sonuc.toStringAsFixed(2)} ₺",
                style: TextStyle(fontSize: 30),
              ),
              Container(
                color: Colors.black,
                height: 2,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _oranlar.keys.length,
                  itemBuilder: _itemList,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemList(BuildContext context, int index) {
    return ListTile(
      title: Text(_oranlar.keys.toList()[index]),
      trailing: Text(_oranlar.values.toList()[index].toStringAsFixed(2)),
    );
  }

  void _hesapla() {
    double? deger = double.tryParse(_kontrol.text);
    double? oran = _oranlar[_secilenkur];
    if (deger != null && oran != null) {
      setState(() {
        _sonuc = deger * oran;
      });
    }
  }

  void _veriCek() async {
    Uri uri = Uri.parse('$_baseUrl?access_key=$_apiKey');
    http.Response response = await http.get(uri);

    if (response.statusCode == 200) {
      try {
        Map<String, dynamic> parsedResponse = jsonDecode(response.body);
        if (parsedResponse.containsKey('rates')) {
          Map<String, dynamic> rates = parsedResponse["rates"];
          if (rates.containsKey('TRY') && rates["TRY"] != null) {
            double? baseTlkur = double.tryParse(rates["TRY"].toString());
            if (baseTlkur != null) {
              rates.forEach((String ulkeKuru, dynamic deger) {
                double? basekur = double.tryParse(deger.toString());
                if (basekur != null) {
                  double tlkuru = baseTlkur / basekur;
                  _oranlar[ulkeKuru] = tlkuru;
                }
              });
              setState(() {});
            } else {
              print("Base TL kuru geçersiz veya null: ${rates["TRY"]}");
            }
          } else {
            print("Rates map içinde 'TRY' anahtarı bulunamadı veya null");
          }
        } else {
          print("'rates' anahtarı yanıt içinde bulunamadı");
        }
      } catch (e) {
        print("JSON parse hatası: $e");
      }
    } else {
      print("HTTP isteği başarısız oldu: ${response.statusCode}");
    }
  }
}
