// Maps Lucide/Feather icon name strings (stored in the categories table)
// to Flutter Material IconData so they render as real icons everywhere.
import 'package:flutter/material.dart';

IconData categoryIconData(String? name) {
  return _map[name] ?? Icons.label_outline;
}

const _map = <String, IconData>{
  'trending-up':      Icons.trending_up,
  'trending-down':    Icons.trending_down,
  'trending-flat':    Icons.trending_flat,
  'briefcase':        Icons.work_outline,
  'laptop':           Icons.laptop_outlined,
  'plus':             Icons.add,
  'home':             Icons.home_outlined,
  'zap':              Icons.bolt_outlined,
  'wifi':             Icons.wifi,
  'wrench':           Icons.build_outlined,
  'shield':           Icons.shield_outlined,
  'utensils':         Icons.restaurant_outlined,
  'shopping-cart':    Icons.shopping_cart_outlined,
  'coffee':           Icons.local_cafe_outlined,
  'package':          Icons.inventory_2_outlined,
  'car':              Icons.directions_car_outlined,
  'fuel':             Icons.local_gas_station_outlined,
  'bus':              Icons.directions_bus_outlined,
  'map-pin':          Icons.location_on_outlined,
  'heart':            Icons.favorite_outline,
  'stethoscope':      Icons.medical_services_outlined,
  'pill':             Icons.medication_outlined,
  'dumbbell':         Icons.fitness_center_outlined,
  'eye':              Icons.visibility_outlined,
  'user':             Icons.person_outline,
  'shirt':            Icons.checkroom_outlined,
  'scissors':         Icons.content_cut_outlined,
  'repeat':           Icons.repeat,
  'film':             Icons.movie_outlined,
  'book':             Icons.book_outlined,
  'star':             Icons.star_outline,
  'baby':             Icons.child_care_outlined,
  'backpack':         Icons.backpack_outlined,
  'trophy':           Icons.emoji_events_outlined,
  'coins':            Icons.monetization_on_outlined,
  'piggy-bank':       Icons.savings_outlined,
  'clock':            Icons.access_time_outlined,
  'graduation-cap':   Icons.school_outlined,
  'credit-card':      Icons.credit_card_outlined,
  'dollar-sign':      Icons.attach_money,
  'gift':             Icons.card_giftcard_outlined,
  'file-text':        Icons.description_outlined,
  'arrow-right-left': Icons.swap_horiz,
  'circle':           Icons.circle_outlined,
  'percent':          Icons.percent,
  'category':         Icons.category_outlined,
};

/// All available icon options for the category picker UI.
const categoryIconOptions = <String>[
  'home', 'briefcase', 'laptop', 'car', 'fuel', 'bus', 'map-pin',
  'utensils', 'shopping-cart', 'coffee', 'package',
  'heart', 'stethoscope', 'pill', 'dumbbell', 'eye', 'shield',
  'user', 'shirt', 'scissors', 'repeat', 'film', 'book', 'star',
  'baby', 'backpack', 'trophy', 'coins',
  'piggy-bank', 'clock', 'graduation-cap', 'credit-card', 'dollar-sign',
  'gift', 'trending-up', 'zap', 'wifi', 'wrench',
  'file-text', 'arrow-right-left', 'circle', 'plus',
];
