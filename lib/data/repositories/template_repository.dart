import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/template.dart';
import '../services/local_cache_service.dart';

class TemplateRepository {
  final SupabaseClient? _client;

  TemplateRepository(this._client);

  final List<String> _orderedCategoryNames = [
    'Trending', 'Anatomy', 'Tattoo', 'Aesthetic', 'Love', 'People', 'Kawaii',
    'Food', 'For Kids', 'For Beginners', 'Holidays', 'Geometry', 'Objects', 'Animals', 'Cars',
    'Nature', 'Architecture'
  ];

  Future<List<Category>> getCategories() async {
    final cached = LocalCacheService.getCachedCategories();
    if (cached.isNotEmpty) {
      return cached;
    }

    if (_client == null) {
      final mocks = getMockCategories();
      await LocalCacheService.saveCategories(mocks);
      return mocks;
    }
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);
      final dbCategories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
      final resolved = resolveAllCategories(dbCategories);
      await LocalCacheService.saveCategories(resolved);
      return resolved;
    } catch (e) {
      final mocks = getMockCategories();
      await LocalCacheService.saveCategories(mocks);
      return mocks;
    }
  }

  Future<List<Template>> getTemplates() async {
    if (_client == null) {
      final mocks = getMockTemplates();
      await LocalCacheService.saveTemplates(mocks);
      return mocks;
    }
    
    final cached = LocalCacheService.getCachedTemplates();
    if (cached.isNotEmpty) {
      return cached;
    }

    try {
      final response = await _client.from('templates').select();
      final templates = (response as List)
          .map((json) => Template.fromJson(json as Map<String, dynamic>))
          .toList();
      await LocalCacheService.saveTemplates(templates);
      return templates;
    } catch (e) {
      final mocks = getMockTemplates();
      await LocalCacheService.saveTemplates(mocks);
      return mocks;
    }
  }

  Future<List<Template>> getTemplatesByCategory(String categoryId) async {
    final allTemplates = await getTemplates();
    final filtered = allTemplates.where((t) => t.categoryId == categoryId).toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }

    final bool isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(categoryId);

    if (_client == null || !isUuid) {
      return getMockTemplates().where((t) => t.categoryId == categoryId).toList();
    }
    try {
      final response = await _client
          .from('templates')
          .select()
          .eq('category_id', categoryId);
      return (response as List)
          .map((json) => Template.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return getMockTemplates().where((t) => t.categoryId == categoryId).toList();
    }
  }

  List<Category> resolveAllCategories(List<Category> dbCategories) {
    return List.generate(_orderedCategoryNames.length, (index) {
      final name = _orderedCategoryNames[index];
      final match = dbCategories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
        orElse: () => Category(
          id: 'cat-${name.toLowerCase().replaceAll(' ', '-')}',
          name: name,
          sortOrder: index + 1,
        ),
      );
      return match;
    });
  }

  List<Category> getMockCategories() {
    return List.generate(_orderedCategoryNames.length, (index) {
      final name = _orderedCategoryNames[index];
      return Category(
        id: 'cat-${name.toLowerCase().replaceAll(' ', '-')}',
        name: name,
        sortOrder: index + 1,
      );
    });
  }

  List<Template> getMockTemplates() {
    return [
      Template(
        id: 't-people-1',
        title: 'Face Profile Line Art',
        categoryId: 'cat-people',
        imageUrl: 'assets/images/templates/people/face_profile_line_art.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-people-2',
        title: 'Simple Face Silhouette',
        categoryId: 'cat-people',
        imageUrl: 'assets/images/templates/people/simple_face_silhouette.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-people-3',
        title: 'Braided Hair Portrait',
        categoryId: 'cat-people',
        imageUrl: 'assets/images/templates/people/braided_hair_portrait.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-people-4',
        title: 'Man with Glasses Portrait',
        categoryId: 'cat-people',
        imageUrl: 'assets/images/templates/people/man_with_glasses_portrait.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-people-5',
        title: 'Flowing Hair Detailed Portrait',
        categoryId: 'cat-people',
        imageUrl: 'assets/images/templates/people/flowing_hair_detailed_portrait.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-people-6',
        title: 'Elderly Man Detailed Portrait',
        categoryId: 'cat-people',
        imageUrl: 'assets/images/templates/people/elderly_man_detailed_portrait.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-people-7',
        title: 'Stylish Portrait Colorful',
        categoryId: 'cat-people',
        imageUrl: 'assets/images/templates/people/stylish_portrait_colorful.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'colorful',
      ),
      Template(
        id: 't-nature-1',
        title: 'Simple Tulip Line Art',
        categoryId: 'cat-nature',
        imageUrl: 'assets/images/templates/nature/simple_tulip_line_art.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-nature-2',
        title: 'Crescent Moon & Stars',
        categoryId: 'cat-nature',
        imageUrl: 'assets/images/templates/nature/crescent_moon_and_stars.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-nature-3',
        title: 'Mountain & Pine Trees',
        categoryId: 'cat-nature',
        imageUrl: 'assets/images/templates/nature/mountain_and_pine_trees.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-nature-4',
        title: 'Blooming Sunflower',
        categoryId: 'cat-nature',
        imageUrl: 'assets/images/templates/nature/blooming_sunflower.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-objects-1',
        title: 'Coffee Mug Line Art',
        categoryId: 'cat-objects',
        imageUrl: 'assets/images/templates/objects/coffee_mug_line_art.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-objects-2',
        title: 'Light Bulb Line Art',
        categoryId: 'cat-objects',
        imageUrl: 'assets/images/templates/objects/light_bulb_line_art.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-objects-3',
        title: 'Vintage Camera',
        categoryId: 'cat-objects',
        imageUrl: 'assets/images/templates/objects/vintage_camera.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-objects-4',
        title: 'Potted Cactus',
        categoryId: 'cat-objects',
        imageUrl: 'assets/images/templates/objects/potted_cactus.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-objects-5',
        title: 'Acoustic Guitar',
        categoryId: 'cat-objects',
        imageUrl: 'assets/images/templates/objects/acoustic_guitar.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-objects-6',
        title: 'Vintage Typewriter',
        categoryId: 'cat-objects',
        imageUrl: 'assets/images/templates/objects/vintage_typewriter.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-objects-7',
        title: 'Retro Boombox Colorful',
        categoryId: 'cat-objects',
        imageUrl: 'assets/images/templates/objects/retro_boombox_colorful.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'colorful',
      ),
      Template(
        id: 't-tattoo-1',
        title: 'Small Rose Line Art',
        categoryId: 'cat-tattoo',
        imageUrl: 'assets/images/templates/tattoo/small_rose_line_art.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-tattoo-2',
        title: 'Crescent Moon & Star',
        categoryId: 'cat-tattoo',
        imageUrl: 'assets/images/templates/tattoo/crescent_moon_and_star.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-tattoo-3',
        title: 'Snake & Dagger',
        categoryId: 'cat-tattoo',
        imageUrl: 'assets/images/templates/tattoo/snake_and_dagger.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-tattoo-4',
        title: 'Symmetrical Butterfly',
        categoryId: 'cat-tattoo',
        imageUrl: 'assets/images/templates/tattoo/symmetrical_butterfly.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-tattoo-5',
        title: 'Skull with Flowers',
        categoryId: 'cat-tattoo',
        imageUrl: 'assets/images/templates/tattoo/skull_with_flowers.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-tattoo-6',
        title: 'Geometric Wolf Head',
        categoryId: 'cat-tattoo',
        imageUrl: 'assets/images/templates/tattoo/geometric_wolf_head.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-tattoo-7',
        title: 'Traditional Rose Colorful',
        categoryId: 'cat-tattoo',
        imageUrl: 'assets/images/templates/tattoo/traditional_rose_colorful.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'colorful',
      ),
      Template(
        id: 't-kawaii-1',
        title: 'Cute Donut Face',
        categoryId: 'cat-kawaii',
        imageUrl: 'assets/images/templates/kawaii/cute_donut_face.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-kawaii-2',
        title: 'Sleepy Cloud',
        categoryId: 'cat-kawaii',
        imageUrl: 'assets/images/templates/kawaii/sleepy_cloud.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-kawaii-3',
        title: 'Chibi Bear with Heart',
        categoryId: 'cat-kawaii',
        imageUrl: 'assets/images/templates/kawaii/chibi_bear_with_heart.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-kawaii-4',
        title: 'Kawaii Boba Tea',
        categoryId: 'cat-kawaii',
        imageUrl: 'assets/images/templates/kawaii/kawaii_boba_tea.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-kawaii-5',
        title: 'Bunny Among Flowers',
        categoryId: 'cat-kawaii',
        imageUrl: 'assets/images/templates/kawaii/bunny_among_flowers.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-kawaii-6',
        title: 'Cat with Bow & Sweets',
        categoryId: 'cat-kawaii',
        imageUrl: 'assets/images/templates/kawaii/cat_with_bow_and_sweets.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-kawaii-7',
        title: 'Kawaii Strawberry Colorful',
        categoryId: 'cat-kawaii',
        imageUrl: 'assets/images/templates/kawaii/kawaii_strawberry_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-holidays-1',
        title: 'Christmas Tree with Star',
        categoryId: 'cat-holidays',
        imageUrl: 'assets/images/templates/holidays/christmas_tree_with_star.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-holidays-2',
        title: 'Jack-o-Lantern Face',
        categoryId: 'cat-holidays',
        imageUrl: 'assets/images/templates/holidays/jack_o_lantern_face.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-holidays-3',
        title: 'Decorated Easter Egg',
        categoryId: 'cat-holidays',
        imageUrl: 'assets/images/templates/holidays/decorated_easter_egg.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-holidays-4',
        title: 'Christmas Stocking',
        categoryId: 'cat-holidays',
        imageUrl: 'assets/images/templates/holidays/christmas_stocking.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-holidays-5',
        title: 'Holly Wreath',
        categoryId: 'cat-holidays',
        imageUrl: 'assets/images/templates/holidays/holly_wreath.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-holidays-6',
        title: "New Year's Fireworks",
        categoryId: 'cat-holidays',
        imageUrl: 'assets/images/templates/holidays/new_years_fireworks.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-holidays-7',
        title: 'Santa Claus Colorful',
        categoryId: 'cat-holidays',
        imageUrl: 'assets/images/templates/holidays/santa_claus_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-geometry-1',
        title: 'Hexagon Nested',
        categoryId: 'cat-geometry',
        imageUrl: 'assets/images/templates/geometry/hexagon_nested.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-geometry-2',
        title: 'Venn Diagram Circles',
        categoryId: 'cat-geometry',
        imageUrl: 'assets/images/templates/geometry/venn_diagram_circles.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-geometry-3',
        title: 'Basic Mandala',
        categoryId: 'cat-geometry',
        imageUrl: 'assets/images/templates/geometry/basic_mandala.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-geometry-4',
        title: 'Geometric Wolf Face',
        categoryId: 'cat-geometry',
        imageUrl: 'assets/images/templates/geometry/geometric_wolf_face.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-geometry-5',
        title: 'Detailed Mandala',
        categoryId: 'cat-geometry',
        imageUrl: 'assets/images/templates/geometry/detailed_mandala.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-geometry-6',
        title: 'Isometric Cube Pattern',
        categoryId: 'cat-geometry',
        imageUrl: 'assets/images/templates/geometry/isometric_cube_pattern.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-geometry-7',
        title: 'Geometric Abstract Colorful',
        categoryId: 'cat-geometry',
        imageUrl: 'assets/images/templates/geometry/geometric_abstract_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-for-kids-1',
        title: 'Smiling Sun',
        categoryId: 'cat-for-kids',
        imageUrl: 'assets/images/templates/for_kids/smiling_sun.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-kids-2',
        title: 'Friendly Duck',
        categoryId: 'cat-for-kids',
        imageUrl: 'assets/images/templates/for_kids/friendly_duck.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-kids-3',
        title: 'Waving Dinosaur',
        categoryId: 'cat-for-kids',
        imageUrl: 'assets/images/templates/for_kids/waving_dinosaur.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-kids-4',
        title: 'Rocket Ship with Stars',
        categoryId: 'cat-for-kids',
        imageUrl: 'assets/images/templates/for_kids/rocket_ship_with_stars.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-kids-5',
        title: 'Pirate Ship',
        categoryId: 'cat-for-kids',
        imageUrl: 'assets/images/templates/for_kids/pirate_ship.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-kids-6',
        title: 'Castle with Towers',
        categoryId: 'cat-for-kids',
        imageUrl: 'assets/images/templates/for_kids/castle_with_towers.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-kids-7',
        title: 'Cheerful Elephant Colorful',
        categoryId: 'cat-for-kids',
        imageUrl: 'assets/images/templates/for_kids/cheerful_elephant_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-for-beginners-1',
        title: 'Simple Apple',
        categoryId: 'cat-for-beginners',
        imageUrl: 'assets/images/templates/for_beginners/simple_apple.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-beginners-2',
        title: 'Basic House',
        categoryId: 'cat-for-beginners',
        imageUrl: 'assets/images/templates/for_beginners/basic_house.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-beginners-3',
        title: 'Sailboat on Waves',
        categoryId: 'cat-for-beginners',
        imageUrl: 'assets/images/templates/for_beginners/sailboat_on_waves.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-beginners-4',
        title: 'Basic Bicycle',
        categoryId: 'cat-for-beginners',
        imageUrl: 'assets/images/templates/for_beginners/basic_bicycle.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-beginners-5',
        title: 'Owl on Branch',
        categoryId: 'cat-for-beginners',
        imageUrl: 'assets/images/templates/for_beginners/owl_on_branch.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-beginners-6',
        title: 'City Skyline',
        categoryId: 'cat-for-beginners',
        imageUrl: 'assets/images/templates/for_beginners/city_skyline.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-for-beginners-7',
        title: 'Smiling Sunflower Colorful',
        categoryId: 'cat-for-beginners',
        imageUrl: 'assets/images/templates/for_beginners/smiling_sunflower_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-food-1',
        title: 'Pizza Slice',
        categoryId: 'cat-food',
        imageUrl: 'assets/images/templates/food/pizza_slice.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-food-2',
        title: 'Ice Cream Cone',
        categoryId: 'cat-food',
        imageUrl: 'assets/images/templates/food/ice_cream_cone.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-food-3',
        title: 'Coffee & Pastry',
        categoryId: 'cat-food',
        imageUrl: 'assets/images/templates/food/coffee_and_pastry.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-food-4',
        title: 'Layered Burger',
        categoryId: 'cat-food',
        imageUrl: 'assets/images/templates/food/layered_burger.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-food-5',
        title: 'Layered Cake Slice',
        categoryId: 'cat-food',
        imageUrl: 'assets/images/templates/food/layered_cake_slice.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-food-6',
        title: 'Fruit Basket',
        categoryId: 'cat-food',
        imageUrl: 'assets/images/templates/food/fruit_basket.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-food-7',
        title: 'Smiling Taco Colorful',
        categoryId: 'cat-food',
        imageUrl: 'assets/images/templates/food/smiling_taco_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-cars-1',
        title: 'Classic Car Side Profile',
        categoryId: 'cat-cars',
        imageUrl: 'assets/images/templates/cars/classic_car_side_profile.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-cars-2',
        title: 'Small Delivery Van',
        categoryId: 'cat-cars',
        imageUrl: 'assets/images/templates/cars/small_delivery_van.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-cars-3',
        title: 'Pickup Truck',
        categoryId: 'cat-cars',
        imageUrl: 'assets/images/templates/cars/pickup_truck.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-cars-4',
        title: 'Vintage Convertible',
        categoryId: 'cat-cars',
        imageUrl: 'assets/images/templates/cars/vintage_convertible.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-cars-5',
        title: 'Sports Car Three-Quarter View',
        categoryId: 'cat-cars',
        imageUrl: 'assets/images/templates/cars/sports_car_three_quarter_view.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-cars-6',
        title: 'Monster Truck',
        categoryId: 'cat-cars',
        imageUrl: 'assets/images/templates/cars/monster_truck.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-cars-7',
        title: 'Red Sports Car Colorful',
        categoryId: 'cat-cars',
        imageUrl: 'assets/images/templates/cars/red_sports_car_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-architecture-1',
        title: 'Eiffel Tower Silhouette',
        categoryId: 'cat-architecture',
        imageUrl: 'assets/images/templates/architecture/eiffel_tower_silhouette.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-architecture-2',
        title: 'Classic Lighthouse',
        categoryId: 'cat-architecture',
        imageUrl: 'assets/images/templates/architecture/classic_lighthouse.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-architecture-3',
        title: 'Taj Mahal',
        categoryId: 'cat-architecture',
        imageUrl: 'assets/images/templates/architecture/taj_mahal.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-architecture-4',
        title: 'Statue of Liberty',
        categoryId: 'cat-architecture',
        imageUrl: 'assets/images/templates/architecture/statue_of_liberty.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-architecture-5',
        title: 'Burj Khalifa',
        categoryId: 'cat-architecture',
        imageUrl: 'assets/images/templates/architecture/burj_khalifa.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-architecture-6',
        title: 'Sydney Opera House',
        categoryId: 'cat-architecture',
        imageUrl: 'assets/images/templates/architecture/sydney_opera_house.png',
        isPremium: true,
        difficulty: 'hard',
        colorType: 'bw',
      ),
      Template(
        id: 't-architecture-7',
        title: 'Big Ben Golden Hour Colorful',
        categoryId: 'cat-architecture',
        imageUrl: 'assets/images/templates/architecture/big_ben_golden_hour_colorful.png',
        isPremium: true,
        difficulty: null,
        colorType: 'colorful',
      ),
      Template(
        id: 't-animals-1',
        title: 'Lion Face',
        categoryId: 'cat-animals',
        imageUrl: 'assets/images/templates/animals/lion_face.png',
        isPremium: false,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-animals-2',
        title: 'Swimming Dolphin',
        categoryId: 'cat-animals',
        imageUrl: 'assets/images/templates/animals/swimming_dolphin.png',
        isPremium: true,
        difficulty: 'easy',
        colorType: 'bw',
      ),
      Template(
        id: 't-animals-3',
        title: 'Rearing Horse',
        categoryId: 'cat-animals',
        imageUrl: 'assets/images/templates/animals/rearing_horse.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
      Template(
        id: 't-animals-4',
        title: 'Owl on Branch',
        categoryId: 'cat-animals',
        imageUrl: 'assets/images/templates/animals/owl_on_branch.png',
        isPremium: true,
        difficulty: 'medium',
        colorType: 'bw',
      ),
    ];
  }
}

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TemplateRepository(client);
});
