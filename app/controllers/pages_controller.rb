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
		@precise_spend = "TK"

		# breakdown of topics for all ads.
		@topics = @page.topic_breakdown

		# TODO: count of ads with a CollectorAd
		# TODO: targetings used

		# TODO: domain names linked to in ads (TODO: has to come from FBPAC or AdLibrary collector)

		# TODO: needs WritablePage for notes.

		respond_to do |format|
		  format.html
		  format.json { render json: {
		  	page: @page.page_name,
		    notes: @page.writable_page&.notes,

		    ads: @count_ads,
		    payers: @payers,

		    min_impressions: @min_impressions,
		    min_spend: @min_spend,
		    precise_spend: @precise_spend,
		    topics: @topics

		  } }
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
