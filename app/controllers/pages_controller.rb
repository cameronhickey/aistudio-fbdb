class PagesController < ApplicationController


	def show
		# 153080620724 is Trump

		@page = Page.find_by(page_id: params[:id])

		# count of ads
		@count_ads = @page.ads.size


		# sum of min impressions for all ads
		@min_impressions = @page.min_impressions

		# count of distinct payers
		@payers = @page.payers

		# sum of spend for all payers
		@min_spend = @page.min_spend
		@max_spend = @page.max_spend
		aarps = @page.ad_archive_report_pages.where(ad_archive_report: AdArchiveReport.order(:scrape_date).last)
		@precise_spend = aarps.sum(:amount_spent)
		@report_count_ads = aarps.sum(:ads_count)

		# breakdown of topics for all ads.
		@topics = @page.topic_breakdown

		# count of ads with a CollectorAd
		fbpac_ads = FbpacAd.where(advertiser: @page.page_name)
		@fbpac_ads_cnt = fbpac_ads.count
		# TODO: targetings used
		@targetings = @page.targeting_methods

		# TODO: domain names linked to in ads (TODO: has to come from FBPAC or AdLibrary collector)

		respond_to do |format|
		  format.html
		  format.json { render json: {
		  	page: @page.page_name,
		    notes: @page.writable_page&.notes,

		    ads: @count_ads,
		    fbpac_ads: @fbpac_ads_cnt,
		    payers: @payers,

		    min_impressions: @min_impressions,
		    min_spend: @min_spend,
		    max_spend: @max_spend,
		    precise_spend: @precise_spend,
		    topics: @topics,

		    targetings: @targetings
		  } }
		end
	end

	def new_since_about_a_week_ago
		@big_spenders = BigSpender.preload(:writable_page).preload(:ad_archive_report_page).preload(:page).order("spend_amount desc")
		respond_to do |format|
		  format.html
		  format.json { render json: @big_spenders }
		end
	end

	def index
		# lists all known payers
		@pages = Page.paginate(page: params[:page], per_page: 30)


		respond_to do |format|
			format.html 
			format.json { render json: @pages }
		end
	end

end
