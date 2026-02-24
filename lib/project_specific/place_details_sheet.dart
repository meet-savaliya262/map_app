import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constant/colorconstant.dart';
import '../controller/place_details_Controller.dart';
import '../pages/direction_page.dart';

class PlaceDetailBottomSheet extends StatelessWidget {
  final PlaceDetailController controller = Get.find<PlaceDetailController>();

  PlaceDetailBottomSheet({super.key});

  void _openDirectionPage(dynamic data) {
    if (data['geometry'] != null) {
      Get.to(() => DirectionPage(
        destinationLocation: LatLng(
            data['geometry']['location']['lat'],
            data['geometry']['location']['lng']
        ),
        destinationName: data['name'] ?? "Destination",
      ));
    }
  }

  void _showFullImage(String photoRef) {
    Get.dialog(
      useSafeArea: false,
      Dialog(
        backgroundColor: ColorConstant.blackColor,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: ColorConstant.blackColor,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  controller.getPhotoUrl(photoRef),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Close Button
              Positioned(
                top: 50,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: ColorConstant.whiteColor, size: 35),
                  onPressed: () => Get.back(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showAllPhotosGallery(List photos) {
    Get.to(() => Scaffold(
      backgroundColor: ColorConstant.whiteColor,
      appBar: AppBar(
        title: const Text("All Photos", style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) => _photoItem(
            photos[index]['photo_reference'],
            photos,
            index,
            photos.length,
            isGallery: true
        ),
      ),
    ));
  }

  void _launchURL(String urlString) async {
    try {
      String cleanUrl = urlString.trim();
      if (cleanUrl.startsWith('tel:')) {
        await launchUrl(Uri.parse(cleanUrl));
        return;
      }
      if (!cleanUrl.startsWith('http')) cleanUrl = 'https://$cleanUrl';
      await launchUrl(Uri.parse(cleanUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar("Error", "Could not open link", snackPosition: SnackPosition.BOTTOM, backgroundColor: ColorConstant.redColor, colorText: ColorConstant.whiteColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = controller.placeData;
    bool hasPhone = data['formatted_phone_number'] != null;
    bool hasWebsite = data['website'] != null;
    List? photos = data['photos'];

    return DraggableScrollableSheet(
      initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(color: ColorConstant.whiteColor, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(
          controller: scrollController,
          children: [
            Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 10), height: 4, width: 40, decoration: BoxDecoration(color: ColorConstant.lightGrayColor, borderRadius: BorderRadius.circular(10)))),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (data['rating'] != null)
                    Row(
                      children: [
                        Text("${data['rating']} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Icon(Icons.star, size: 16, color: ColorConstant.orangeColor),
                        Text(" (${data['user_ratings_total'] ?? '0'}) · Location", style: const TextStyle(color: ColorConstant.greenColor)),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildMainBtn(Icons.directions, "Directions", ColorConstant.secondary, true, () => _openDirectionPage(data)),
                  if (hasWebsite) ...[const SizedBox(width: 8), _buildMainBtn(Icons.public, "Website", ColorConstant.greenColor.withValues(alpha: 0.60), false, () => _launchURL(data['website']))],
                  if (hasPhone) ...[const SizedBox(width: 8), _buildMainBtn(Icons.call, "Call", ColorConstant.secondary, false, () => _launchURL("tel:${data['formatted_phone_number']}"))],
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (photos != null && photos.isNotEmpty) _buildAdvancedImageGrid(photos),

            const Divider(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (data['opening_hours'] != null && data['opening_hours']['weekday_text'] != null)
                    _buildExpansionHours(data['opening_hours']),
                  _buildDetailRow(Icons.location_on, data['formatted_address'] ?? ""),
                  if (hasPhone) _buildDetailRow(Icons.phone, data['formatted_phone_number'] ?? ""),
                ],
              ),
            ),

            const Divider(height: 30),

            if (data['reviews'] != null && (data['reviews'] as List).isNotEmpty)
              _buildReviewsSection(data['reviews']),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedImageGrid(List photos) {
    int displayCount = photos.length > 6 ? 6 : photos.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _buildPhotoRow(photos, 0, displayCount),
          if (displayCount > 3) ...[const SizedBox(height: 5), _buildPhotoRow(photos, 3, displayCount)],
        ],
      ),
    );
  }

  Widget _buildPhotoRow(List photos, int startIndex, int displayCount) {
    int rowCount = displayCount - startIndex;
    if (rowCount <= 0) return const SizedBox();
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(flex: 2, child: _photoItem(photos[startIndex]['photo_reference'], photos, startIndex, displayCount)),
          if (rowCount > 1) ...[
            const SizedBox(width: 5),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _photoItem(photos[startIndex + 1]['photo_reference'], photos, startIndex + 1, displayCount)),
                  if (rowCount > 2) ...[
                    const SizedBox(height: 5),
                    Expanded(child: _photoItem(photos[startIndex + 2]['photo_reference'], photos, startIndex + 2, displayCount)),
                  ],
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _photoItem(String ref, List allPhotos, int index, int displayCount, {bool isGallery = false}) {
    bool isLastVisible = !isGallery && index == 5 && allPhotos.length > 6;
    return InkWell(
      onTap: () => isLastVisible ? _showAllPhotosGallery(allPhotos) : _showFullImage(ref),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(controller.getPhotoUrl(ref), fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: ColorConstant.lightGrayColor)),
          ),
          if (isLastVisible)
            Container(
              decoration: BoxDecoration(color: ColorConstant.blackColor.withValues(alpha: 0.40), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text("+${allPhotos.length - 5}\nMore", textAlign: TextAlign.center, style: const TextStyle(color: ColorConstant.whiteColor, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(List reviews) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: const Icon(Icons.rate_review_outlined, color: ColorConstant.secondary, size: 20),
          title: Text("Reviews (${reviews.length})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          children: reviews.map((rev) => _buildSingleReview(rev)).toList(),
        ),
      ),
    );
  }

  Widget _buildSingleReview(Map rev) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundImage: rev['profile_photo_url'] != null ? NetworkImage(rev['profile_photo_url']) : null),
          title: Text(rev['author_name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Row(
            children: [
              _buildSmallStars(rev['rating'] ?? 0),
              const SizedBox(width: 8),
              Text(rev['relative_time_description'] ?? "", style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        if (rev['text'] != null) Padding(padding: const EdgeInsets.only(left: 55, bottom: 10), child: Text(rev['text'], style: const TextStyle(fontSize: 13))),
        const Divider(),
      ],
    );
  }

  Widget _buildSmallStars(num rating) => Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, size: 12, color: ColorConstant.orangeColor)));

  Widget _buildMainBtn(IconData icon, String label, Color color, bool isFilled, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isFilled ? color : ColorConstant.whiteColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: ColorConstant.lightGrayColor)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isFilled ? ColorConstant.whiteColor : color, size: 18), const SizedBox(width: 5), Text(label, style: TextStyle(color: isFilled ? ColorConstant.whiteColor : ColorConstant.blackColor, fontSize: 12))]),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Icon(icon, color: ColorConstant.secondary, size: 20), const SizedBox(width: 15), Expanded(child: Text(text, style: const TextStyle(fontSize: 14)))]));
  }

  Widget _buildExpansionHours(Map hours) {
    bool isOpen = hours['open_now'] ?? false;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(Icons.access_time, color: isOpen ? ColorConstant.greenColor : ColorConstant.redColor, size: 20),
      title: Text(isOpen ? "Open Now" : "Closed", style: const TextStyle(fontSize: 14)),
      children: (hours['weekday_text'] as List).map((day) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(day.toString(), style: const TextStyle(fontSize: 13)),
      )).toList(),
    );
  }
}