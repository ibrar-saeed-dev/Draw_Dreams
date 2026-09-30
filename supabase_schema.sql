-- 1. Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Create templates table
CREATE TABLE IF NOT EXISTS public.templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_premium BOOLEAN NOT NULL DEFAULT false,
    difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    color_type TEXT CHECK (color_type IN ('bw', 'colorful')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

-- Allow public read access to categories and templates
CREATE POLICY "Allow public read access to categories" 
ON public.categories FOR SELECT TO public USING (true);

CREATE POLICY "Allow public read access to templates" 
ON public.templates FOR SELECT TO public USING (true);

-- 3. Seed initial categories
INSERT INTO public.categories (name, sort_order) VALUES
('Animals', 1),
('Anime', 2),
('Cars', 3),
('Nature', 4),
('Aesthetic', 5)
ON CONFLICT (name) DO NOTHING;

-- 4. Seed initial templates (Using placeholder outline URLs - we will link these to our categories)
-- Note: Replace these URLs with your actual hosted template outline images in the Supabase Storage bucket.
DO $$
DECLARE
    animals_id UUID;
    anime_id UUID;
    cars_id UUID;
    nature_id UUID;
    aesthetic_id UUID;
BEGIN
    SELECT id INTO animals_id FROM public.categories WHERE name = 'Animals' LIMIT 1;
    SELECT id INTO anime_id FROM public.categories WHERE name = 'Anime' LIMIT 1;
    SELECT id INTO cars_id FROM public.categories WHERE name = 'Cars' LIMIT 1;
    SELECT id INTO nature_id FROM public.categories WHERE name = 'Nature' LIMIT 1;
    SELECT id INTO aesthetic_id FROM public.categories WHERE name = 'Aesthetic' LIMIT 1;

    -- Insert Animals Templates
    INSERT INTO public.templates (title, category_id, image_url, is_premium) VALUES
    ('Cute Kitten', animals_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', false),
    ('Majestic Lion', animals_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', true)
    ON CONFLICT DO NOTHING;

    -- Insert Anime Templates
    INSERT INTO public.templates (title, category_id, image_url, is_premium) VALUES
    ('Chibi Hero', anime_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', false),
    ('Anime Ninja', anime_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', true)
    ON CONFLICT DO NOTHING;

    -- Insert Cars Templates
    INSERT INTO public.templates (title, category_id, image_url, is_premium) VALUES
    ('Sports Car', cars_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', false),
    ('Vintage Beetle', cars_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', true)
    ON CONFLICT DO NOTHING;

    -- Insert Nature Templates
    INSERT INTO public.templates (title, category_id, image_url, is_premium) VALUES
    ('Simple Rose', nature_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', false),
    ('Palm Tree', nature_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', false)
    ON CONFLICT DO NOTHING;

    -- Insert Aesthetic Templates
    INSERT INTO public.templates (title, category_id, image_url, is_premium) VALUES
    ('Minimalist Hands', aesthetic_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', false),
    ('Retro Sun', aesthetic_id, 'https://raw.githubusercontent.com/flutter/website/main/examples/layout/lakes/images/lake.jpg', true)
    ON CONFLICT DO NOTHING;
END $$;

-- 5. Create saved_drawings table for user galleries
CREATE TABLE IF NOT EXISTS public.saved_drawings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- references auth.users(id) in real supabase environment
    image_url TEXT NOT NULL,
    source_template_id UUID REFERENCES public.templates(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for saved_drawings
ALTER TABLE public.saved_drawings ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own saved drawings
CREATE POLICY "Allow users to read their own drawings"
ON public.saved_drawings FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Allow users to insert their own drawings
CREATE POLICY "Allow users to insert their own drawings"
ON public.saved_drawings FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own drawings
CREATE POLICY "Allow users to delete their own drawings"
ON public.saved_drawings FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 6. Setup storage bucket user-drawings configuration
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-drawings', 'user-drawings', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for user-drawings bucket
CREATE POLICY "Allow authenticated users to upload drawings"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'user-drawings');

CREATE POLICY "Allow public read access to drawings"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-drawings');


-- 7. Create lessons table
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    thumbnail_url TEXT NOT NULL,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    color_type TEXT CHECK (color_type IN ('bw', 'colorful')),
    step_count INT NOT NULL DEFAULT 0,
    completion_count INT NOT NULL DEFAULT 0,
    is_premium BOOLEAN NOT NULL DEFAULT false,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for lessons
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;

-- Allow public read access to lessons
CREATE POLICY "Allow public read access to lessons" 
ON public.lessons FOR SELECT TO public USING (true);

-- 8. Setup storage bucket lessons configuration
INSERT INTO storage.buckets (id, name, public)
VALUES ('lessons', 'lessons', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for lessons bucket
CREATE POLICY "Allow authenticated users to upload lessons"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'lessons');

-- Allow public read access to lessons storage bucket
CREATE POLICY "Allow public read access to lessons storage"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'lessons');

-- Seed initial lessons
DO $$
DECLARE
    animals_id UUID;
    anime_id UUID;
    cars_id UUID;
    nature_id UUID;
    aesthetic_id UUID;
BEGIN
    SELECT id INTO animals_id FROM public.categories WHERE name = 'Animals' LIMIT 1;
    SELECT id INTO anime_id FROM public.categories WHERE name = 'Anime' LIMIT 1;
    SELECT id INTO cars_id FROM public.categories WHERE name = 'Cars' LIMIT 1;
    SELECT id INTO nature_id FROM public.categories WHERE name = 'Nature' LIMIT 1;
    SELECT id INTO aesthetic_id FROM public.categories WHERE name = 'Aesthetic' LIMIT 1;

    -- Insert Easy Lessons
    INSERT INTO public.lessons (title, thumbnail_url, difficulty, color_type, step_count, completion_count, is_premium, category_id) VALUES
    ('Pencil Grasp & Basics', 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=400&auto=format&fit=crop', 'easy', 'bw', 3, 3942, false, aesthetic_id),
    ('Simple Circle Drawing', 'https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?q=80&w=400&auto=format&fit=crop', 'easy', 'bw', 4, 1530, false, nature_id)
    ON CONFLICT DO NOTHING;

    -- Insert Medium Lessons
    INSERT INTO public.lessons (title, thumbnail_url, difficulty, color_type, step_count, completion_count, is_premium, category_id) VALUES
    ('Understanding 3D Shapes', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=400&auto=format&fit=crop', 'medium', 'colorful', 5, 2130, false, aesthetic_id),
    ('Anime Face Proportions', 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?q=80&w=400&auto=format&fit=crop', 'medium', 'colorful', 6, 854, true, anime_id)
    ON CONFLICT DO NOTHING;

    -- Insert Hard Lessons
    INSERT INTO public.lessons (title, thumbnail_url, difficulty, color_type, step_count, completion_count, is_premium, category_id) VALUES
    ('Shading & Blending Masterclass', 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?q=80&w=400&auto=format&fit=crop', 'hard', 'colorful', 8, 394, true, aesthetic_id),
    ('Advanced Animal Portrait', 'https://images.unsplash.com/photo-1614027164847-1b2809eb7b9b?q=80&w=400&auto=format&fit=crop', 'hard', 'colorful', 10, 130, true, animals_id)
    ON CONFLICT DO NOTHING;
END $$;

-- 9. Create user_uploads table for reusable imported images
CREATE TABLE IF NOT EXISTS public.user_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    outline_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for user_uploads
ALTER TABLE public.user_uploads ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own uploads
CREATE POLICY "Allow users to read their own uploads"
ON public.user_uploads FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Allow users to insert their own uploads
CREATE POLICY "Allow users to insert their own uploads"
ON public.user_uploads FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own uploads
CREATE POLICY "Allow users to delete their own uploads"
ON public.user_uploads FOR DELETE
TO authenticated
USING (auth.uid() = user_id);



