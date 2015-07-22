Repair::Application.routes.draw do

  get "cron/index"
  get "cron/reset"
  post "cron/update"

  post "config/update"
  get "config/edit"
	devise_for :users
	root to: "runs#index"
  get "runs/update_templates"
  post "runs/run_all"
  get "runs/report"
  post "runs/download_templates"
  post "runs/refresh_report"
  get "runs/kill"

  resources :runs
end
