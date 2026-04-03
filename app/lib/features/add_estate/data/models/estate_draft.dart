class EstateDraft {
  const EstateDraft({
    required this.title,
    required this.description,
    required this.location,
    required this.pricePerMonth,
    required this.listingType,
    required this.category,
    this.lat,
    this.lng,
    this.imagePaths = const <String>[],
    this.videoPaths = const <String>[],
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.livingRooms = 1,
    this.kitchens = 1,
    this.numberOfFloors = 1,
    this.floorArea,
    this.constructionYear,
    this.isFinished = true,
    this.amenities = const <String>[],
    this.nearbyPlaces = const <String, int>{},
  });

  final String title;
  final String description;
  final String location;
  final double pricePerMonth;
  final String listingType;
  final String category;
  final double? lat;
  final double? lng;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final int kitchens;
  final int numberOfFloors;
  final double? floorArea;
  final int? constructionYear;
  final bool isFinished;
  final List<String> amenities;
  final Map<String, int> nearbyPlaces;

  EstateDraft copyWith({
    String? title,
    String? description,
    String? location,
    double? pricePerMonth,
    String? listingType,
    String? category,
    double? lat,
    double? lng,
    List<String>? imagePaths,
    List<String>? videoPaths,
    int? bedrooms,
    int? bathrooms,
    int? livingRooms,
    int? kitchens,
    int? numberOfFloors,
    double? floorArea,
    int? constructionYear,
    bool? isFinished,
    List<String>? amenities,
    Map<String, int>? nearbyPlaces,
  }) {
    return EstateDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      listingType: listingType ?? this.listingType,
      category: category ?? this.category,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPaths: videoPaths ?? this.videoPaths,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      livingRooms: livingRooms ?? this.livingRooms,
      kitchens: kitchens ?? this.kitchens,
      numberOfFloors: numberOfFloors ?? this.numberOfFloors,
      floorArea: floorArea ?? this.floorArea,
      constructionYear: constructionYear ?? this.constructionYear,
      isFinished: isFinished ?? this.isFinished,
      amenities: amenities ?? this.amenities,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'pricePerMonth': pricePerMonth,
      'listingType': listingType,
      'category': category,
      'lat': lat,
      'lng': lng,
      'imagePaths': imagePaths,
      'videoPaths': videoPaths,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'livingRooms': livingRooms,
      'kitchens': kitchens,
      'numberOfFloors': numberOfFloors,
      'floorArea': floorArea,
      'constructionYear': constructionYear,
      'isFinished': isFinished,
      'amenities': amenities,
      'nearbyPlaces': nearbyPlaces,
    };
  }
}
