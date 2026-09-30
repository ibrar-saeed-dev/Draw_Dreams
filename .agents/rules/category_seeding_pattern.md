# Category Seeding Workflow & Rules for AR Drawing App

Whenever the user requests generating and seeding new template images for a category (e.g. Kawaii, Holidays, Anime, Animals, etc.), perform the entire workflow in a **SINGLE CYCLE**:

1. **SHA-256 Hash Uniqueness Check**:
   - Compute SHA-256 checksums of all existing template images in `assets/images/templates/` across all categories.
   - Verify each newly generated image against this list immediately after generation. If a hash collides, regenerate the image.

2. **Image Generation**:
   - Generate all 7 images (2 Easy B&W, 2 Medium B&W, 2 Hard B&W, 1 Colorful) using prompt specifications.

3. **Local Assets & Repositories**:
   - Save images locally to `assets/images/templates/<category_slug>/`.
   - Update `pubspec.yaml` assets section to include `- assets/images/templates/<category_slug>/`.
   - Add mock template objects to `getMockTemplates()` in `lib/data/repositories/template_repository.dart`.
   - Add mock lesson objects to `_getMockLessons()` in `lib/data/repositories/lesson_repository.dart`.

4. **Live Supabase Sync**:
   - Update `templates` DB table (7 rows) with public HTTPS storage URLs (`https://wqovmdxvonlslemjxqnn.supabase.co/storage/v1/object/public/templates/<category_slug>/<filename>.png`) and set difficulty/color_type/is_premium.
   - Update `lessons` DB table (7 rows) with `thumbnail_url`, difficulty, step_count, completion_count.
   - Deduplicate any repeated rows in `lessons` or `templates` tables.

5. **Category & Difficulty Filtering**:
   - Ensure `_buildNormalLessonsSliver` in `lib/features/lessons/lessons_screen.dart` handles both database UUIDs and local slug IDs (`cat-<name>`).

6. **Output Requirements**:
   - Provide copy-pasteable SQL queries for `templates` and `lessons`.
   - Provide individual visual proof images alongside titles, difficulty, color_type, is_premium, public URL, and SHA-256 hash.
   - Update `walkthrough.md` with complete documentation.
