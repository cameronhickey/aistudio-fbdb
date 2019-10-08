class Payer < ApplicationRecord
	has_many :ads, primary_key: :name, foreign_key: :funding_entity

	def min_spend
		ads.joins(:impressions).group(:archive_id).sum(:min_spend).values.reduce(&:+)
	end

	def advertisers
		Page.where(page_id: ads.unscope(:order).select("distinct page_id"))
	end

	def advertiser_spend 
		advertisers.map(&:spend).reduce(&:+)
	end

	def min_impressions
		#ads.joins(:impressions).group(:ad_archive_id).max(:crawl_date).sum(:min_impressions)
		puts "needs to limit to just the most recent in each group"
		ads.joins(:impressions).group(:archive_id).sum(:min_impressions).values.reduce(&:+)
	end

	# TODO should go in a mixin.
	# TODO: should happen in SQL.
	def topic_breakdown
		breakdown = Hash[*ads.unscope(:order).joins(:ad_topics).joins(:topics).select("topic, sum(coalesce(ad_topics.proportion, cast(1.0 as double precision))) as proportion").group(:topic).map{|a| [a.topic, a.proportion]}.flatten]
		total = breakdown.values.reduce(&:+)
		breakdown_proportions = {}
		breakdown.each do | topic, amt |
			breakdown_proportions[topic] = amt.to_f / total
		end
		breakdown_proportions
	end

end
