import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../utils/Extensions/app_common.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../model/ContactNumberListModel.dart';
import '../../network/RestApis.dart';
import 'package:share/share.dart';

class ShareScreen extends StatefulWidget {
  final int? rideId;
  final int? regionId;

  ShareScreen({this.rideId, this.regionId});

  @override
  ShareScreenState createState() => ShareScreenState();
}

class ShareScreenState extends State<ShareScreen> {
  List<ContactModel> sosListData = [];
  LatLng? sourceLocation;

  bool sendNotification = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    getCurrentUserLocation();
    appStore.setLoading(true);
    await getSosList(regionId: widget.regionId).then((value) {
      sosListData.addAll(value.data!);
      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> adminSosNotify() async {
    sendNotification = false;
    appStore.setLoading(true);
    Map req = {
      "ride_request_id": widget.rideId,
      "latitude": sourceLocation!.latitude,
      "longitude": sourceLocation!.longitude,
    };
    await adminNotify(request: req).then((value) {
      appStore.setLoading(false);
      sendNotification = true;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);

      log(error.toString());
    });
  }

  Future<void> getCurrentUserLocation() async {
    final geoPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      sourceLocation = LatLng(geoPosition.latitude, geoPosition.longitude);
    });
    print("L O C A T I O N N N N N N: $sourceLocation");
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var ride_request_id = widget.rideId;
    double latitud = sourceLocation?.latitude ?? 0.0;
    double longitud = sourceLocation?.longitude ?? 0.0;
    print(latitud);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Observer(builder: (context) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.share_location, color: Colors.red, size: 50),
                    SizedBox(height: 20),
                    Text('Compartir detalles del viaje?',
                        style: boldTextStyle(color: Colors.red)),
                    SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            Share.share(
                                "Hola! Voy en viaje con Remisses Saenz Peña\nViaje #$ride_request_id\n https://www.google.com/maps/@$latitud,$longitud,15z ",
                                subject:
                                    'Te comparto mi ubicación de Viaje #$ride_request_id');
                          },
                          child: const Text(
                            'Compartir',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    /*
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(language.notifyAdmin, style: boldTextStyle()),
                            if (sendNotification) SizedBox(height: 4),
                            if (sendNotification)
                              Text(language.notifiedSuccessfully,
                                  style:
                                      secondaryTextStyle(color: Colors.green)),
                          ],
                        ),
                        inkWellWidget(
                          onTap: () {
                            adminSosNotify();
                          },
                          child: Icon(Icons.notification_add_outlined,
                              color: primaryColor),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    */
                    Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: sosListData.length,
                          itemBuilder: (_, index) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(sosListData[index].title.validate(),
                                          style: boldTextStyle()),
                                      SizedBox(height: 4),
                                      Text(
                                          sosListData[index]
                                              .contactNumber
                                              .validate(),
                                          style: primaryTextStyle()),
                                    ],
                                  ),
                                  inkWellWidget(
                                    onTap: () {
                                      launchUrl(
                                          Uri.parse(
                                              'tel:${sosListData[index].contactNumber}'),
                                          mode: LaunchMode.externalApplication);
                                    },
                                    child: Icon(Icons.call),
                                  ),
                                ],
                              ),
                            );
                          }),
                    )
                  ],
                ),
              ),
              Visibility(
                visible: appStore.isLoading,
                child: IntrinsicHeight(
                  child: loaderWidget(),
                ),
              )
            ],
          );
        }),
      ],
    );
  }
}
