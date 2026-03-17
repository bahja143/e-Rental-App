import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/estate_draft.dart';
import '../data/repositories/add_estate_repository.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AddEstateScreen extends StatefulWidget {
  const AddEstateScreen({super.key});

  @override
  State<AddEstateScreen> createState() => _AddEstateScreenState();
}

class _AddEstateScreenState extends State<AddEstateScreen> {
  int _step = 0;
  bool _publishing = false;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _publishEstate() async {
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final draft = EstateDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      pricePerMonth: price,
    );
    if (draft.title.isEmpty || draft.location.isEmpty || draft.pricePerMonth <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete title, location, and price.')),
      );
      return;
    }

    setState(() => _publishing = true);
    final ok = await AddEstateRepository().publishEstate(draft);
    if (!mounted) return;
    setState(() => _publishing = false);
    if (ok) {
      context.go(AppRoutes.home);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not publish property. Please try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Add Location' : _step == 1 ? 'Add Photos' : 'Property Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => _step > 0 ? setState(() => _step--) : context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _step == 0
            ? _buildLocationStep()
            : _step == 1
                ? _buildPhotosStep()
                : _buildDetailsStep(),
      ),
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where is your property?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the address so renters can find it.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        AppTextField(
          controller: _locationController,
          hintText: 'Address or area',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.greyBarelyMedium),
        ),
        const SizedBox(height: 24),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 48, color: AppColors.greyBarelyMedium),
                const SizedBox(height: 12),
                Text('Select on map', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.greyBarelyMedium)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Next',
            onPressed: () => setState(() => _step = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add property photos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          'Upload at least 3 photos. Good photos help renters find your property.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _PhotoPlaceholder(onTap: () {}),
            const SizedBox(width: 12),
            _PhotoPlaceholder(onTap: () {}),
            const SizedBox(width: 12),
            _PhotoPlaceholder(onTap: () {}, isEmpty: true),
          ],
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Next',
            onPressed: () => setState(() => _step = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _titleController,
          hintText: 'Property title',
          prefixIcon: const Icon(Icons.home_work_outlined, size: 20, color: AppColors.greyBarelyMedium),
        ),
        const SizedBox(height: 15),
        AppTextField(
          controller: _priceController,
          hintText: 'Price per month (\$)',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.attach_money, size: 20, color: AppColors.greyBarelyMedium),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Description',
            filled: true,
            fillColor: AppColors.greySoft1,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: _publishing ? 'Publishing...' : 'Publish',
            isLoading: _publishing,
            onPressed: _publishing ? null : _publishEstate,
          ),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.onTap, this.isEmpty = false});

  final VoidCallback onTap;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isEmpty ? AppColors.greySoft1 : AppColors.greySoft2,
          borderRadius: BorderRadius.circular(12),
          border: isEmpty ? Border.all(color: AppColors.greyBarelyMedium, width: 2, style: BorderStyle.solid) : null,
        ),
        child: isEmpty
            ? const Icon(Icons.add, size: 40, color: AppColors.greyBarelyMedium)
            : const Icon(Icons.image, size: 40, color: AppColors.greyBarelyMedium),
      ),
    );
  }
}
