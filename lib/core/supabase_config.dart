/// Identificadores públicos do projeto Supabase e do login com Google.
///
/// Nada aqui é segredo: a URL e a chave publicável foram feitas pra ir no
/// app (a proteção dos dados vem das policies RLS do banco, não do sigilo da
/// chave). O Client Secret do Google e a chave `service_role` NUNCA entram
/// no código — o primeiro vive só no painel do Supabase.
const kSupabaseUrl = 'https://kcaqemuoncgijerlpvhi.supabase.co';
const kSupabasePublishableKey =
    'sb_publishable_MRFwN8K7mmB6CPw1vJ5P6g_mAdtDLEP';

/// Client ID do tipo "Aplicativo da Web" no Google Cloud. É o `serverClientId`
/// do `google_sign_in`: o token sai com ele como público e o Supabase o aceita.
const kGoogleWebClientId =
    '646137645063-cc0psigb9bctmec2jgn26p0tr8qlbltl.apps.googleusercontent.com';
