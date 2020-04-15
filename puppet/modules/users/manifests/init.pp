class users (
  Hash[String, Hash] $users = {},
) {
  include sudo

  # Users hash is passed from Foreman
  create_resources(users::account, $users)

}
